//===============================TX===============================
`timescale 1ns/1ps
module Top_TX (
    input  wire        clk_in,
    input  wire        rst,
    input  wire [7:0]  switches,
    input  wire [19:0] switches_err,   // [19:18]=par0 ... [1:0]=par9
    input  wire        start_cod,

    // Debug
    output wire        led_clk_debug,
    output wire        led_par_valid,
    output wire [19:0] leds_codigo20,  // 10 pares alterados MSB→LSB (monitor)

    // Enlace a RX
    output wire        link_clk,
    output wire        link_rst,
    /* (REMOVIDO) output wire [1:0]  link_data, */
    output wire        link_valid,
    output wire        link_frame_end
);

    // ---------------- Reloj lento ----------------
    wire clk_lento;
    divisor_frecuencia_v3 #(.DIV(12_500_000)) u_div (
        .clk_in (clk_in),
        .rst    (rst),
        .clk_out(clk_lento)
    );
    assign led_clk_debug = clk_lento;

    // ------------- Capturador palabra ------------
    wire [7:0] palabra_sw;
    Entrada_8bits u_Inicio_Cod (
        .clk      (clk_lento),
        .rst      (rst),
        .start_cod(start_cod),
        .switches (switches),
        .salida_o (palabra_sw)
    );

    // ------------- One-shot de inicio ------------
    reg start_req, iniciar_reg;
    always @(posedge clk_lento or posedge rst) begin
        if (rst) begin
            start_req   <= 1'b0;
            iniciar_reg <= 1'b0;
        end else begin
            if (start_cod && !start_req) begin
                start_req   <= 1'b1;
                iniciar_reg <= 1'b1;
            end else begin
                iniciar_reg <= 1'b0;
                if (start_req) start_req <= 1'b0;
            end
        end
    end
    wire iniciar_cod = iniciar_reg;

    // ----------------- Codificador (22 bits = 11 pares) -----------------
    wire s1_cod, s2_cod;
    wire listo_cod;
    wire par_valid_cod;
    wire [21:0] codigo_o_acumulado;

    CodConv3 #(
        .K(3), .N(8), .RESPUESTA(6'b111011),
        .GUARD_PAIRS(1)
    ) u_cod (
        .clk               (clk_lento),
        .rst               (rst),
        .iniciar           (iniciar_cod),
        .mensaje           (palabra_sw),
        .salida1_o         (s1_cod),                 // G1
        .salida2_o         (s2_cod),                 // G2
        .listo_o           (listo_cod),
        .par_valid_o       (par_valid_cod),          // 11 pulsos (incluye guarda)
        .codigo_o_acumulado(codigo_o_acumulado)
    );

    // ==================== Ruido (pares de error) ====================
    wire [1:0] par_error_raw;   // [1]=MSB del par, [0]=LSB del par
    wire       err_valid, err_done;

    Ruido_Pares20 u_ruido (
        .clk       (clk_lento),
        .rst       (rst),
        .start     (iniciar_cod),      // arranca con iniciar_cod
        .vector20  (switches_err),     // [19:18]=par0 ... [1:0]=par9
        .advance_i (par_valid_cod),    // avanza con el coder
        .par_o     (par_error_raw),
        .valid_o   (err_valid),
        .done_o    (err_done)
    );

    // XOR en línea (0-latencia hacia RX) con gating por par_valid_cod
    wire err_g1 = par_valid_cod ? par_error_raw[1] : 1'b0;
    wire err_g2 = par_valid_cod ? par_error_raw[0] : 1'b0;
    wire [1:0] par_alter = { s1_cod ^ err_g1,  s2_cod ^ err_g2 };

    // -------------------- Debug & Enlace ----------------
    assign led_par_valid  = par_valid_cod;   // mismo strobe que viaja al RX
    assign link_clk       = clk_lento;
    assign link_rst       = rst;

    // NOTA: mantenemos una señal interna para ondas/depuración
    wire [1:0] link_data = par_alter;  // <-- SOLO INTERNA, ya no es puerto

    assign link_valid     = par_valid_cod;   // 11 pulsos (incluye guarda)
    assign link_frame_end = listo_cod;       // fin tras 22 bits

    // --------- MONITOR: Acumulador_Sec_Erronea (instancia normal) ---------
    Acumulador_Sec_Erronea u_mon (
      .clk           (clk_lento),
      .rst           (rst),
      .par_valid     (par_valid_cod),
      .par_pair      (par_alter),      // {G1',G2'} ya alterado
      .leds_codigo20 (leds_codigo20)   // 10 pares MSB→LSB (sin guarda)
    );

endmodule
