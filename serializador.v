module serializador (
  input wire clk,
  input wire rst,
  input wire en,
  input wire [19:0] sec_cod,
  output reg [1:0] par_cod,
  output reg valid,
  output reg listo
);

  reg [3:0] indice;  // 0 a 10: 10 pares + 1 ciclo final para activar 'listo'

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      indice    <= 0;
      par_cod <= 2'b00;
      valid     <= 0;
      listo     <= 0;
    end else if (en && !listo) begin
      if (indice < 10) begin
        par_cod <= sec_cod[19 - indice*2 -: 2];  // Extrae par actual
        valid     <= 1;
        indice    <= indice + 1;
      end else begin
        valid <= 0;
        listo <= 1;  // Se activa justo después del último 'valid'
      end
    end else begin
      valid <= 0;
    end
  end
 endmodule 