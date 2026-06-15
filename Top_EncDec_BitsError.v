`timescale 1ns/1ps
module Top_EncDec_BitsError (
    // Entradas al TX
    input  wire        clk_in,
    input  wire        rst,
    input  wire [7:0]  switches,
    input  wire [19:0] switches_err,
    input  wire        start_cod,

    // Debug TX
    output wire        led_clk_tx_debug,
    output wire        led_par_valid_tx,
    output wire [19:0] leds_codigo20,

    // Debug RX
    output wire        led_clk_rx_debug,
    output wire        led_par_valid_rx,
    output wire        dec_listo,

    // ---- Salidas del RX ----
    output wire [9:0]  palabra_o,    // 10 bits (igual que antes)
    output wire [7:0]  palabra8_o    // 8 MSB (nuevo)
);

  // -------- Nets de enlace TX→RX --------
  wire        link_clk;
  wire        link_rst;
  wire        link_valid;
  wire        link_frame_end;  // -> en del RX

  // ================== TX ==================
  Top_TX u_tx (
    .clk_in        (clk_in),
    .rst           (rst),
    .switches      (switches),
    .switches_err  (switches_err),
    .start_cod     (start_cod),

    .led_clk_debug (led_clk_tx_debug),
    .led_par_valid (led_par_valid_tx),
    .leds_codigo20 (leds_codigo20),

    .link_clk      (link_clk),
    .link_rst      (link_rst),
    .link_valid    (link_valid),
    .link_frame_end(link_frame_end)
  );

  // ================== RX ==================
  wire [9:0] palabra_w;
  wire [7:0] palabra8_w;
  wire       listo_w;

  Top_RX #(.L(20), .DEPTH(50)) u_rx (
    .link_clk    (link_clk),        // TX.link_clk -> RX.link_clk
    .link_rst    (link_rst),        // TX.link_rst -> RX.link_rst
    .en          (link_frame_end),  // TX.link_frame_end -> RX.en
    .sec_cod     (leds_codigo20),   // TX.leds_codigo20 -> RX.sec_cod

    .bit_decod_o (),                // (no usado aquí)
    .palabra_o   (palabra_w),
    .listo_o     (listo_w),
    .palabra8_o  (palabra8_w)       // NUEVO
  );

  // ================== Indicadores RX ==================
  assign led_clk_rx_debug = link_clk;    // clock del enlace
  assign led_par_valid_rx = link_valid;  // proxy visual del strobe del TX
  assign dec_listo        = listo_w;

  // ================== Salidas puras ==================
  assign palabra_o  = palabra_w;
  assign palabra8_o = palabra8_w;

endmodule
