module Entrada_8bits (
  input  wire clk,
  input  wire rst,
  input  wire start_cod,
  input  wire [7:0] switches,
  output reg  [7:0] salida_o
);
  reg start_cod_d;
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      salida_o    <= 8'b0;
      start_cod_d <= 1'b0;
    end else begin
      start_cod_d <= start_cod;
      if (start_cod & ~start_cod_d)
        salida_o <= switches;  // captura atómica con el mismo pulso que usa el coder
    end
  end
endmodule
