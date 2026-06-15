`timescale 1ns/1ps
module Top_Decod_Viterbi_K3_tbk #(
  parameter integer DATA_BITS = 10  // nº de pares REALES (8 data + 2 tails del encoder)
)(
  input  wire clk,
  input  wire rst,               // reset por trama (dec_soft_rst)
  input  wire par_valido_i,      // 10 pulsos válidos
  input  wire s1_i,
  input  wire s2_i,

  output reg  [DATA_BITS-1:0] palabra_o, // palabra completa (MSB_FIRST)
  output reg                  listo_o     // pulso 1 ciclo al terminar traceback
);
  // --------- Constantes / tipos ----------
  localparam [5:0] INF = 6'd63;
  localparam [1:0] A=2'b00, B=2'b01, C=2'b10, D=2'b11;

  // --------- Distancias de Hamming (2b) ----------
  wire [1:0] d00, d01, d10, d11;
  HammingGen_K3 u_h (
    .dec_in_i({s1_i,s2_i}),
    .d00(d00), .d01(d01), .d10(d10), .d11(d11)
  );

  // --------- Métricas y estados activos ----------
  reg [5:0] M_A, M_B, M_C, M_D;
  reg       act_A, act_B, act_C, act_D;

  // Candidatos (mismo mapa que en tu diseño)
  wire [5:0] cand_A_from_A = act_A ? (M_A + {4'b0, d00}) : INF;
  wire [5:0] cand_A_from_B = act_B ? (M_B + {4'b0, d11}) : INF;

  wire [5:0] cand_B_from_C = act_C ? (M_C + {4'b0, d10}) : INF;
  wire [5:0] cand_B_from_D = act_D ? (M_D + {4'b0, d01}) : INF;

  wire [5:0] cand_C_from_A = act_A ? (M_A + {4'b0, d11}) : INF;
  wire [5:0] cand_C_from_B = act_B ? (M_B + {4'b0, d00}) : INF;

  wire [5:0] cand_D_from_C = act_C ? (M_C + {4'b0, d01}) : INF;
  wire [5:0] cand_D_from_D = act_D ? (M_D + {4'b0, d10}) : INF;

  reg [5:0] best_A_c, best_B_c, best_C_c, best_D_c;
  reg [1:0] best_A_pred, best_B_pred, best_C_pred, best_D_pred;
  reg       best_A_u,    best_B_u,    best_C_u,    best_D_u;
  reg       next_act_A,  next_act_B,  next_act_C,  next_act_D;

  always @* begin
    // A <= (A,u=0/00) vs (B,u=0/11)
    next_act_A = act_A | act_B;
    if (cand_A_from_A <= cand_A_from_B) begin best_A_c=cand_A_from_A; best_A_pred=A; best_A_u=1'b0; end
    else                                 begin best_A_c=cand_A_from_B; best_A_pred=B; best_A_u=1'b0; end

    // B <= (C,u=0/10) vs (D,u=0/01)
    next_act_B = act_C | act_D;
    if (cand_B_from_C <= cand_B_from_D) begin best_B_c=cand_B_from_C; best_B_pred=C; best_B_u=1'b0; end
    else                                 begin best_B_c=cand_B_from_D; best_B_pred=D; best_B_u=1'b0; end

    // C <= (A,u=1/11) vs (B,u=1/00)
    next_act_C = act_A | act_B;
    if (cand_C_from_A <= cand_C_from_B) begin best_C_c=cand_C_from_A; best_C_pred=A; best_C_u=1'b1; end
    else                                 begin best_C_c=cand_C_from_B; best_C_pred=B; best_C_u=1'b1; end

    // D <= (C,u=1/01) vs (D,u=1/10)
    next_act_D = act_C | act_D;
    if (cand_D_from_C <= cand_D_from_D) begin best_D_c=cand_D_from_C; best_D_pred=C; best_D_u=1'b1; end
    else                                 begin best_D_c=cand_D_from_D; best_D_pred=D; best_D_u=1'b1; end
  end

  // --------- Memorias de supervivientes (por estado y tiempo) ----------
  // pred_X[t]: 2b con el estado predecesor elegido para llegar a X en el paso t
  // bit_X[t] : 1b con el bit (u) asociado a esa transición
  reg [1:0] pred_A [0:DATA_BITS-1];
  reg [1:0] pred_B [0:DATA_BITS-1];
  reg [1:0] pred_C [0:DATA_BITS-1];
  reg [1:0] pred_D [0:DATA_BITS-1];

  reg       bit_A  [0:DATA_BITS-1];
  reg       bit_B  [0:DATA_BITS-1];
  reg       bit_C  [0:DATA_BITS-1];
  reg       bit_D  [0:DATA_BITS-1];

  // Índice de paso (0..DATA_BITS-1)
  reg [4:0] step_idx_q;

  // Señal para registrar subida/bajada de par_valido_i
  reg par_v_q;
  always @(posedge clk or posedge rst) begin
    if (rst) par_v_q <= 1'b0;
    else     par_v_q <= par_valido_i;
  end
  wire sop = par_valido_i & ~par_v_q; // start-of-packet (primer par)
  wire eop = ~par_valido_i &  par_v_q; // end-of-packet (tras último par)

  // --------- Traceback control ----------
  reg        tb_busy;
  reg [1:0]  tb_state;
  reg [4:0]  tb_idx;          // 0..DATA_BITS-1
  reg [DATA_BITS-1:0] palabra_tb; // shift mientras hacemos traceback

  // --------- Proceso principal ----------
  integer t;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      // métricas/activos
      M_A<=0; M_B<=INF; M_C<=INF; M_D<=INF;
      act_A<=1; act_B<=0; act_C<=0; act_D<=0;

      step_idx_q <= 5'd0;

      tb_busy    <= 1'b0;
      tb_state   <= A;
      tb_idx     <= 5'd0;
      palabra_tb <= {DATA_BITS{1'b0}};
      palabra_o  <= {DATA_BITS{1'b0}};
      listo_o    <= 1'b0;

    end else begin
      listo_o <= 1'b0; // pulso de 1 ciclo

      // ---- Fase de recolección (cuando llegan los 10 pares) ----
      if (par_valido_i && !tb_busy) begin
        // Guardar decisiones de este paso
        pred_A[step_idx_q] <= best_A_pred;  bit_A[step_idx_q] <= best_A_u;
        pred_B[step_idx_q] <= best_B_pred;  bit_B[step_idx_q] <= best_B_u;
        pred_C[step_idx_q] <= best_C_pred;  bit_C[step_idx_q] <= best_C_u;
        pred_D[step_idx_q] <= best_D_pred;  bit_D[step_idx_q] <= best_D_u;

        // Avanzar métricas/activos
        M_A   <= next_act_A ? best_A_c : INF;
        M_B   <= next_act_B ? best_B_c : INF;
        M_C   <= next_act_C ? best_C_c : INF;
        M_D   <= next_act_D ? best_D_c : INF;

        act_A <= next_act_A;
        act_B <= next_act_B;
        act_C <= next_act_C;
        act_D <= next_act_D;

        // Avanza índice
        if (step_idx_q < DATA_BITS-1)
          step_idx_q <= step_idx_q + 5'd1;

      end

      // ---- Detectar fin de datos y arrancar traceback ----
      if (eop && !tb_busy) begin
        // Elegir estado final mínimo con las métricas actuales
        // (ya incluyen el último paso porque se actualizaron en el ciclo anterior)
        if (act_A && (M_A <= M_B) && (M_A <= M_C) && (M_A <= M_D)) tb_state <= A;
        else if (act_B && (M_B <= M_A) && (M_B <= M_C) && (M_B <= M_D)) tb_state <= B;
        else if (act_C && (M_C <= M_A) && (M_C <= M_B) && (M_C <= M_D)) tb_state <= C;
        else tb_state <= D;

        tb_idx     <= DATA_BITS-1;       // arrancar desde el último tiempo
        palabra_tb <= {DATA_BITS{1'b0}}; // limpiar acumulador
        tb_busy    <= 1'b1;
      end

      // ---- Traceback (1 ciclo por bit) ----
      if (tb_busy) begin
        // Leer bit y predecesor correspondientes al estado actual
        reg        b;
        reg [1:0]  p;
        case (tb_state)
          A: begin b = bit_A [tb_idx]; p = pred_A[tb_idx]; end
          B: begin b = bit_B [tb_idx]; p = pred_B[tb_idx]; end
          C: begin b = bit_C [tb_idx]; p = pred_C[tb_idx]; end
          default: begin b = bit_D [tb_idx]; p = pred_D[tb_idx]; end
        endcase

        // Construir palabra MSB_FIRST: desplazamos e insertamos LSB = b
        palabra_tb <= {palabra_tb[DATA_BITS-2:0], b};
        tb_state   <= p;

        if (tb_idx == 0) begin
          // Listo: publicar y soltar pulso
          palabra_o <= {palabra_tb[DATA_BITS-2:0], b};
          listo_o   <= 1'b1;

          // Preparar para el siguiente frame (el top nos reseteará con rst)
          tb_busy    <= 1'b0;
          step_idx_q <= 5'd0;

          // Opcional: reiniar métricas (no estrictamente necesario aquí)
          M_A<=0; M_B<=INF; M_C<=INF; M_D<=INF;
          act_A<=1; act_B<=0; act_C<=0; act_D<=0;

        end else begin
          tb_idx <= tb_idx - 5'd1;
        end
      end
    end
  end
endmodule
