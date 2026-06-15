//===============================RX===============================
// Top_RX (puro): instancia serializador y decodificador.
// Mantiene salida de 10 bits y agrega palabra8_o = palabra_o[9:2].
//================================================================
`timescale 1ns/1ps
module Top_RX #(
    parameter integer L     = 20,
    parameter integer DEPTH = 50
)(
    input  wire        link_clk,
    input  wire        link_rst,
    input  wire        en,              // Habilita el serializador
    input  wire [19:0] sec_cod,         // Entrada paralela de 20 bits

    output wire        bit_decod_o,
    output wire [9:0]  palabra_o,       // palabra completa (10b)
    output wire        listo_o,
    output wire [7:0]  palabra8_o       // 8 MSB de la palabra decodificada
);

    // Señales internas entre serializador y decodificador
    wire [1:0] par_cod;
    wire       valid;
    wire       listo;

    // Instancia del serializador
    serializador u_ser (
        .clk      (link_clk),
        .rst      (link_rst),
        .en       (en),
        .sec_cod  (sec_cod),
        .par_cod  (par_cod),
        .valid    (valid),
        .listo    (listo)
    );

    // Salida interna del decodificador (10 bits)
    wire [9:0] palabra_w;

    // Instancia del decodificador Viterbi
    Top_Decod_Viterbi_K3 #(.L(L), .DEPTH(DEPTH)) u_dec (
        .clk            (link_clk),
        .rst            (link_rst),
        .par_valido_i   (valid),
        .salida1_i      (par_cod[1]),
        .salida2_i      (par_cod[0]),
        .bit_decod_o    (bit_decod_o),
        .salida_final_o (palabra_w),
        .listo_o        (listo_o)
    );

    // Mapeos de salida
    assign palabra_o  = palabra_w;
    assign palabra8_o = palabra_w[9:2];

endmodule
