// ==========================================================
// ACS_K3  (Add-Compare-Select por destino, K=3, 4 estados)
// - Recibe métricas previas, activaciones y distancias Hamming
// - Devuelve mejor métrica por destino, predecesor y bit u
// - También entrega las activaciones de la siguiente etapa
// ==========================================================

module ACS_K3 #(
  parameter [5:0] INF = 6'd63
)(
  // Métricas previas y actividad
  input  wire [5:0] M_A, M_B, M_C, M_D,
  input  wire       act_A, act_B, act_C, act_D,

  // Distancias de Hamming (patrones de salida del codificador)
  input  wire [1:0] d00, d01, d10, d11,

  // Resultados por destino
  output reg  [5:0] best_A_c, best_B_c, best_C_c, best_D_c,
  output reg  [1:0] best_A_pred, best_B_pred, best_C_pred, best_D_pred,
  output reg        best_A_u,    best_B_u,    best_C_u,    best_D_u,

  // Activaciones para la siguiente etapa
  output reg        next_act_A, next_act_B, next_act_C, next_act_D
);

  // Estados A=00, B=01, C=10, D=11
  localparam A = 2'b00, B = 2'b01, C = 2'b10, D = 2'b11;

  // Candidatos por destino (respetando actividad y INF)
  wire [5:0] cand_A_from_A = act_A ? (M_A + {4'b0, d00}) : INF;
  wire [5:0] cand_A_from_B = act_B ? (M_B + {4'b0, d11}) : INF;

  wire [5:0] cand_B_from_C = act_C ? (M_C + {4'b0, d10}) : INF;
  wire [5:0] cand_B_from_D = act_D ? (M_D + {4'b0, d01}) : INF;

  wire [5:0] cand_C_from_A = act_A ? (M_A + {4'b0, d11}) : INF;
  wire [5:0] cand_C_from_B = act_B ? (M_B + {4'b0, d00}) : INF; // FIX: B->C usa d00

  wire [5:0] cand_D_from_C = act_C ? (M_C + {4'b0, d01}) : INF;
  wire [5:0] cand_D_from_D = act_D ? (M_D + {4'b0, d10}) : INF;

  always @* begin
    // A <= min( A--u0/00 , B--u0/11 )
    next_act_A  = act_A | act_B;
    if (cand_A_from_A <= cand_A_from_B) begin
      best_A_c    = cand_A_from_A;
      best_A_pred = A;
      best_A_u    = 1'b0;
    end else begin
      best_A_c    = cand_A_from_B;
      best_A_pred = B;
      best_A_u    = 1'b0;
    end

    // B <= min( C--u0/10 , D--u0/01 )
    next_act_B  = act_C | act_D;
    if (cand_B_from_C <= cand_B_from_D) begin
      best_B_c    = cand_B_from_C;
      best_B_pred = C;
      best_B_u    = 1'b0;
    end else begin
      best_B_c    = cand_B_from_D;
      best_B_pred = D;
      best_B_u    = 1'b0;
    end

    // C <= min( A--u1/11 , B--u1/00 )
    next_act_C  = act_A | act_B;
    if (cand_C_from_A <= cand_C_from_B) begin
      best_C_c    = cand_C_from_A;
      best_C_pred = A;
      best_C_u    = 1'b1;
    end else begin
      best_C_c    = cand_C_from_B;
      best_C_pred = B;
      best_C_u    = 1'b1;
    end

    // D <= min( C--u1/01 , D--u1/10 )
    next_act_D  = act_C | act_D;
    if (cand_D_from_C <= cand_D_from_D) begin
      best_D_c    = cand_D_from_C;
      best_D_pred = C;
      best_D_u    = 1'b1;
    end else begin
      best_D_c    = cand_D_from_D;
      best_D_pred = D;
      best_D_u    = 1'b1;
    end
  end

endmodule 
