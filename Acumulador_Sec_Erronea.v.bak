module Acumulador_Sec_Erronea #(
  parameter integer TOTAL_PAIRS   = 11, // 10 útiles + 1 guarda
  parameter integer STORE_PAIRS   = 10  // cuántos pares acumular (sin guarda)
)(
  input  wire        clk,
  input  wire        rst,
  input  wire        par_valid,      // strobe del coder (incluye guarda)
  input  wire [1:0]  par_pair,       // {G1',G2'} ya alterado (lo que va al link)
  output reg  [19:0] leds_codigo20   // pares útiles MSB→LSB (par0->[19:18])
);
  reg        pv_d;
  reg  [3:0] idx; // 0..10

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      pv_d         <= 1'b0;
      idx          <= 4'd0;
      leds_codigo20<= 20'd0;
    end else begin
      pv_d <= par_valid;

      // SOP
      if (par_valid & ~pv_d) begin
        idx                <= 4'd0;
        leds_codigo20      <= 20'd0;
        leds_codigo20[19 -: 2] <= par_pair;         // par0 -> [19:18]
        idx                <= 4'd1;
      end
      // interior: pares 1..9, ignora idx==10 (guarda)
      else if (par_valid) begin
        if (idx < STORE_PAIRS) begin
          leds_codigo20[19 - (idx*2) -: 2] <= par_pair;
          idx <= idx + 4'd1;
        end
      end
    end
  end
endmodule
