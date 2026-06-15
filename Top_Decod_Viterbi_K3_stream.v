`timescale 1ns/1ps
module Top_Decod_Viterbi_K3_stream #(
  parameter integer DATA_BITS   = 10,  // nº de pares REALES (datos+colas)
  parameter integer L           = 20,  // profundidad de camino para REA
  parameter integer EXTRA_FLUSH = 0    // pasos de flush adicionales opcionales
)(
  input  wire clk, rst,
  input  wire par_valido_i,  // 10 pulsos (o 11 si entra guarda)
  input  wire s1_i,          // G1
  input  wire s2_i,          // G2
  output reg  bit_o,
  output reg  bit_valid_o
);
  // -------- Distancias de Hamming --------
  wire [1:0] d00, d01, d10, d11;
  HammingGen_K3 u_h (.dec_in_i({s1_i,s2_i}), .d00(d00), .d01(d01), .d10(d10), .d11(d11));

  // -------- Contadores data/flush --------
  reg [4:0] data_cnt_q;   // cuenta 0..DATA_BITS
  reg [7:0] flush_cnt_q;
  reg       flush_q;

  // Paso real: consume datos (avanza contador de datos)
  wire real_step  = par_valido_i && (data_cnt_q < DATA_BITS);

  // Pulso extra (guarda) tras DATA_BITS: consúmelo sin avanzar data_cnt_q
  wire guard_step = par_valido_i && (data_cnt_q == DATA_BITS);

  // Flush: pasos con distancias 0 para asentar el camino
  localparam integer FL_BASE       = (L>0) ? L : 0;  // usar L completo
  localparam integer FLUSH_STEPS   = FL_BASE + ((EXTRA_FLUSH>0)?EXTRA_FLUSH:0);
  wire               flush_step    = flush_q;

  // Habilitación general de actualización de ACS/REA
  wire wr_en_step = real_step || guard_step || flush_step;

  // data_cnt_q solo avanza en pasos reales
  always @(posedge clk or posedge rst) begin
    if (rst)              data_cnt_q <= 5'd0;
    else if (real_step)   data_cnt_q <= data_cnt_q + 5'd1;
  end

  // dispare flush cuando cae par_valido_i y ya consumimos todos los DATA_BITS
  wire end_of_data = (!par_valido_i && (data_cnt_q == DATA_BITS) && !flush_q);

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      flush_q     <= 1'b0;
      flush_cnt_q <= 8'd0;
    end else begin
      if (end_of_data) begin
        if (FLUSH_STEPS != 0) begin
          flush_q     <= 1'b1;
          flush_cnt_q <= FLUSH_STEPS - 1;
        end
      end else if (flush_q && wr_en_step) begin
        if (flush_cnt_q == 8'd0) flush_q <= 1'b0;
        else                     flush_cnt_q <= flush_cnt_q - 8'd1;
      end
    end
  end

  // -------- ACS (7,5) --------
  localparam [5:0] INF = 6'd63;
  localparam [1:0] A=2'b00, B=2'b01, C=2'b10, D=2'b11;

  reg [5:0] M_A, M_B, M_C, M_D;
  reg       act_A, act_B, act_C, act_D;

  // Distancias filtradas: en flush no se penaliza (0)
  wire [1:0] d00_f = flush_q ? 2'd0 : d00;
  wire [1:0] d01_f = flush_q ? 2'd0 : d01;
  wire [1:0] d10_f = flush_q ? 2'd0 : d10;
  wire [1:0] d11_f = flush_q ? 2'd0 : d11;

  // Candidatos
  wire [5:0] cand_A_from_A = act_A ? (M_A + {4'b0, d00_f}) : INF;
  wire [5:0] cand_A_from_B = act_B ? (M_B + {4'b0, d11_f}) : INF;

  wire [5:0] cand_B_from_C = act_C ? (M_C + {4'b0, d10_f}) : INF;
  wire [5:0] cand_B_from_D = act_D ? (M_D + {4'b0, d01_f}) : INF;

  wire [5:0] cand_C_from_A = act_A ? (M_A + {4'b0, d11_f}) : INF;
  wire [5:0] cand_C_from_B = act_B ? (M_B + {4'b0, d00_f}) : INF;

  wire [5:0] cand_D_from_C = act_C ? (M_C + {4'b0, d01_f}) : INF;
  wire [5:0] cand_D_from_D = act_D ? (M_D + {4'b0, d10_f}) : INF;

  reg [5:0] best_A_c, best_B_c, best_C_c, best_D_c;
  reg [1:0] best_A_pred, best_B_pred, best_C_pred, best_D_pred;
  reg       best_A_u,    best_B_u,    best_C_u,    best_D_u;
  reg       next_act_A,  next_act_B,  next_act_C,  next_act_D;

  // ---- Rama NORMAL SIEMPRE (no apagar B/C/D en flush) ----
  always @* begin
    // A <= min(A+00, B+11), u=0
    next_act_A = act_A | act_B;
    if (cand_A_from_A <= cand_A_from_B) begin best_A_c=cand_A_from_A; best_A_pred=A; end
    else                                 begin best_A_c=cand_A_from_B; best_A_pred=B; end
    best_A_u = 1'b0;

    // B <= min(C+10, D+01), u=0
    next_act_B = act_C | act_D;
    if (cand_B_from_C <= cand_B_from_D) begin best_B_c=cand_B_from_C; best_B_pred=C; end
    else                                 begin best_B_c=cand_B_from_D; best_B_pred=D; end
    best_B_u = 1'b0;

    // C <= min(A+11, B+00), u=1
    next_act_C = act_A | act_B;
    if (cand_C_from_A <= cand_C_from_B) begin best_C_c=cand_C_from_A; best_C_pred=A; end
    else                                 begin best_C_c=cand_C_from_B; best_C_pred=B; end
    best_C_u = 1'b1;

    // D <= min(C+01, D+10), u=1
    next_act_D = act_C | act_D;
    if (cand_D_from_C <= cand_D_from_D) begin best_D_c=cand_D_from_C; best_D_pred=C; end
    else                                 begin best_D_c=cand_D_from_D; best_D_pred=D; end
    best_D_u = 1'b1;
  end

  // Selector de mínimo global (para emisión en modo normal)
  wire [1:0] end_state_w;
  wire [5:0] gmin_w;
  MetricSelector_K3 u_sel (
    .mA(best_A_c), .mB(best_B_c), .mC(best_C_c), .mD(best_D_c),
    .enA(next_act_A), .enB(next_act_B), .enC(next_act_C), .enD(next_act_D),
    .min_state_o(end_state_w),
    .min_metric_o(gmin_w)
  );

  // -------- REA --------
  reg [L-1:0] path_A, path_B, path_C, path_D;
  reg [L-1:0] path_A_n, path_B_n, path_C_n, path_D_n;

  wire [L-1:0] sel_pred_A = (best_A_pred==A) ? path_A :
                            (best_A_pred==B) ? path_B : {L{1'b0}};
  wire [L-1:0] sel_pred_B = (best_B_pred==C) ? path_C :
                            (best_B_pred==D) ? path_D : {L{1'b0}};
  wire [L-1:0] sel_pred_C = (best_C_pred==A) ? path_A :
                            (best_C_pred==B) ? path_B : {L{1'b0}};
  wire [L-1:0] sel_pred_D = (best_D_pred==C) ? path_C :
                            (best_D_pred==D) ? path_D : {L{1'b0}};

  always @* begin
    path_A_n = { sel_pred_A[L-2:0], best_A_u };
    path_B_n = { sel_pred_B[L-2:0], best_B_u };
    path_C_n = { sel_pred_C[L-2:0], best_C_u };
    path_D_n = { sel_pred_D[L-2:0], best_D_u };
  end

  // -------- Emisión --------
  reg [7:0] step_cnt_q;

  // Durante flush, solo SE LEE desde A; el ACS siguió normal
  wire force_A_path = flush_q;
  wire [1:0] end_state_sel = force_A_path ? 2'b00 : end_state_w;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      M_A<=0; M_B<=INF; M_C<=INF; M_D<=INF;
      act_A<=1; act_B<=0; act_C<=0; act_D<=0;
      path_A<={L{1'b0}}; path_B<={L{1'b0}}; path_C<={L{1'b0}}; path_D<={L{1'b0}};
      step_cnt_q<=8'd0;
      bit_o<=1'b0; bit_valid_o<=1'b0;
    end else begin
      bit_valid_o <= 1'b0;

      if (wr_en_step) begin
        // actualizar métricas/activaciones
        M_A   <= next_act_A ? best_A_c : INF;
        M_B   <= next_act_B ? best_B_c : INF;
        M_C   <= next_act_C ? best_C_c : INF;
        M_D   <= next_act_D ? best_D_c : INF;

        act_A <= next_act_A;
        act_B <= next_act_B;
        act_C <= next_act_C;
        act_D <= next_act_D;

        // REA
        path_A <= path_A_n;
        path_B <= path_B_n;
        path_C <= path_C_n;
        path_D <= path_D_n;

        // conteo de pasos procesados (datos + guarda + flush)
        step_cnt_q <= step_cnt_q + 8'd1;

        // Emitir desde PATH REGISTRADO con umbral L
        if (step_cnt_q >= L) begin
          case (end_state_sel)
            2'b00: bit_o <= path_A[L-1];
            2'b01: bit_o <= path_B[L-1];
            2'b10: bit_o <= path_C[L-1];
            default: bit_o <= path_D[L-1];
          endcase
          bit_valid_o <= 1'b1;
        end
      end
    end
  end
endmodule
