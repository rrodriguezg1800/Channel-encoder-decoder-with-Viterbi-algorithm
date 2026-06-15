// Divisor de Frecuencia, limpio de truncados
module divisor_frecuencia_v3 #(parameter integer DIV = 12_500_000)(
    input  wire clk_in,
    input  wire rst,
    output reg  clk_out
);
    localparam integer CNTRW = $clog2(DIV);
    localparam [CNTRW-1:0] DIVM1 = DIV-1;

    reg [CNTRW-1:0] contador;

    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            contador <= {CNTRW{1'b0}};
            clk_out  <= 1'b0;
        end else if (contador == DIVM1) begin
            contador <= {CNTRW{1'b0}};
            clk_out  <= ~clk_out;
        end else begin
            contador <= contador + {{(CNTRW-1){1'b0}},1'b1};
        end
    end
endmodule
