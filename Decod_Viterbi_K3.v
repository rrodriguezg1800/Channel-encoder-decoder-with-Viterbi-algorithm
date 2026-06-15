// ==========================================================
// Decod_Viterbi_K3  (ACS por destino, SOLO FLUSH + padding 00)
// - Escribe en TB: DATA_BITS + PAD_STEPS
// - En flush: salta PAD_STEPS (padding) y guarda DATA_BITS reales
// ==========================================================

module Decod_Viterbi_K3 #(
    parameter integer L     = 20, // Cambios para tener más historia en el traceback
    parameter integer DEPTH = 50
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       par_valido_i,
    input  wire [1:0] dec_in_i,

    // Salidas principales del decodificador
    output wire        bit_decod_o,
    output wire [9:0]  salida_final_o,
    output wire        listo_o,
    output wire        flush_q
);

    // ---------------- configuración de frame ----------------
    localparam integer DATA_BITS   = 10;                 // Bits reales de datos
    localparam integer TAIL_BITS   = 2;                  // K-1 (K=3) Bits de cola
    localparam integer PAD_STEPS   = L + TAIL_BITS;      // 20 + 2 = 22
    localparam integer TOTAL_STEPS = DATA_BITS + PAD_STEPS;
    localparam [5:0]   INF         = 6'd63;              // Métrica infinita

`ifndef SYNTHESIS
    initial if (DEPTH < TOTAL_STEPS)
        $error("DEPTH=%0d < TOTAL_STEPS=%0d (aumenta DEPTH, p.ej. 32)",
               DEPTH, TOTAL_STEPS);
`endif

    // ---------------- Métricas y actividad ----------------
    reg [5:0] M_A, M_B, M_C, M_D;
    reg       act_A, act_B, act_C, act_D;

    // ---------- Distancias de Hamming ----------
    wire [1:0] d00, d01, d10, d11;

    // Control de padding/frame
    wire        wr_en_step;
    wire [1:0]  dec_in_eff;
    wire        pad_active;
    wire [$clog2(PAD_STEPS+1)-1:0] pad_cnt;

    // Paso actual (desde FrameControl)
    wire [$clog2(TOTAL_STEPS):0] step_cnt_w;

    // Traceback
    wire tb_valido_w, tb_bit_w;

    // ACS
    wire [5:0] best_A_c, best_B_c, best_C_c, best_D_c;
    wire [1:0] best_A_pred, best_B_pred, best_C_pred, best_D_pred;
    wire       best_A_u,    best_B_u,    best_C_u,    best_D_u;
    wire       next_act_A,  next_act_B,  next_act_C,  next_act_D;

    // Min selector
    wire [1:0] end_state_w;
    wire [5:0] gmin_w;

    // Empaque de survivors
    wire [7:0] surv_pred_pack = {best_D_pred, best_C_pred, best_B_pred, best_A_pred};
    wire [3:0] surv_u_pack    = {best_D_u,    best_C_u,    best_B_u,    best_A_u};

    // ---------------- Instancias ----------------

    HammingGen_K3 hamming_inst (
        .dec_in_i(dec_in_eff),
        .d00(d00), .d01(d01), .d10(d10), .d11(d11)
    );

    PaddingGen_K3 #(.DATA_BITS(DATA_BITS), .PAD_STEPS(PAD_STEPS)) pad_inst (
        .clk(clk), .rst(rst),
        .par_valido_i(par_valido_i),
        .dec_in_i(dec_in_i),
        .step_cnt_i(step_cnt_w),           // usa el contador del FrameControl
        .wr_en_step_o(wr_en_step),
        .dec_in_eff_o(dec_in_eff),
        .pad_active_o(pad_active),
        .pad_cnt_o(pad_cnt)
    );

    ACS_K3 #(.INF(INF)) acs_inst (
        .M_A(M_A), .M_B(M_B), .M_C(M_C), .M_D(M_D),
        .act_A(act_A), .act_B(act_B), .act_C(act_C), .act_D(act_D),
        .d00(d00), .d01(d01), .d10(d10), .d11(d11),
        .best_A_c(best_A_c), .best_B_c(best_B_c), .best_C_c(best_C_c), .best_D_c(best_D_c),
        .best_A_pred(best_A_pred), .best_B_pred(best_B_pred), .best_C_pred(best_C_pred), .best_D_pred(best_D_pred),
        .best_A_u(best_A_u), .best_B_u(best_B_u), .best_C_u(best_C_u), .best_D_u(best_D_u),
        .next_act_A(next_act_A), .next_act_B(next_act_B), .next_act_C(next_act_C), .next_act_D(next_act_D)
    );

    MetricSelector_K3 selector_inst (
        .mA(best_A_c), .mB(best_B_c), .mC(best_C_c), .mD(best_D_c),
        .enA(next_act_A), .enB(next_act_B), .enC(next_act_C), .enD(next_act_D),
        .min_state_o(end_state_w),
        .min_metric_o(gmin_w)
    );

    Traceback_K3 #(.DEPTH(DEPTH), .L(L)) tb_inst (
        .clk(clk), .rst(rst),
        .wr_en_i(wr_en_step),
        .flush_i(flush_q),
        .surv_pred_i(surv_pred_pack),
        .surv_u_i   (surv_u_pack),
        .end_state_i(end_state_w),
        .valido_o(tb_valido_w),
        .bit_o(tb_bit_w)
    );

    // FrameControl entrega flush, salida, listo y step_cnt
    wire [DATA_BITS-1:0] salida_final_w;
    wire bit_decod_w, listo_w, flush_w;

    FrameControl #(
        .DATA_BITS(DATA_BITS),
        .PAD_STEPS(PAD_STEPS),
        .TOTAL_STEPS(TOTAL_STEPS)
    ) frame_ctrl_inst (
        .clk(clk), .rst(rst),
        .wr_en_step(wr_en_step),
        .tb_valido_i(tb_valido_w),
        .tb_bit_i(tb_bit_w),
        .flush_o(flush_w),
        .bit_decod_o(bit_decod_w),
        .salida_final_o(salida_final_w),
        .listo_o(listo_w),
        .step_cnt_o(step_cnt_w)
    );

    // Mapear salidas del decodificador
    assign flush_q        = flush_w;
    assign bit_decod_o    = bit_decod_w;
    assign salida_final_o = salida_final_w;
    assign listo_o        = listo_w;

    // ---------------- Secuencial: actualización de métricas ----------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            M_A<=0; M_B<=INF; M_C<=INF; M_D<=INF;
            act_A<=1; act_B<=0; act_C<=0; act_D<=0;
        end else if (wr_en_step) begin
            M_A   <= next_act_A ? best_A_c : INF;
            M_B   <= next_act_B ? best_B_c : INF;
            M_C   <= next_act_C ? best_C_c : INF;
            M_D   <= next_act_D ? best_D_c : INF;

            act_A <= next_act_A;
            act_B <= next_act_B;
            act_C <= next_act_C;
            act_D <= next_act_D;
        end
    end

endmodule
