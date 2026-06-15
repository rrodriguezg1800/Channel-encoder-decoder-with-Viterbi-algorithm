module HammingGen_K3 (
    input  wire [1:0] dec_in_i,
    output wire [1:0] d00,
    output wire [1:0] d01,
    output wire [1:0] d10,
    output wire [1:0] d11
);

    // XOR + suma de bits para obtener distancia de Hamming
    wire [1:0] xor00 = dec_in_i ^ 2'b00;
    wire [1:0] xor01 = dec_in_i ^ 2'b01;
    wire [1:0] xor10 = dec_in_i ^ 2'b10;
    wire [1:0] xor11 = dec_in_i ^ 2'b11;

    assign d00 = xor00[0] + xor00[1];
    assign d01 = xor01[0] + xor01[1];
    assign d10 = xor10[0] + xor10[1];
    assign d11 = xor11[0] + xor11[1];

endmodule 
