`timescale 1ns/1ps
module List_Viterbi
#(
    parameter integer N_BITS     = 10,
    parameter integer IDXW       = 4,
    parameter         MSB_FIRST  = 1
)(
    input  wire                    clk,
    input  wire                    rst,
    input  wire                    start_i,
    input  wire                    bit_i,
    input  wire                    bit_valid_i,

    output reg  [N_BITS-1:0]       palabra_o,
    output reg                     listo_o,
    output reg                     ocupado_o,
    output reg  [IDXW-1:0]         idx_o
);
    reg [IDXW-1:0] count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            palabra_o <= {N_BITS{1'b0}};
            listo_o   <= 1'b0;
            ocupado_o <= 1'b0;
            idx_o     <= {IDXW{1'b0}};
            count     <= {IDXW{1'b0}};
        end else begin
            if (start_i) begin
                palabra_o <= {N_BITS{1'b0}};
                listo_o   <= 1'b0;
                ocupado_o <= 1'b1;
                idx_o     <= {IDXW{1'b0}};
                count     <= {IDXW{1'b0}};
            end else if (bit_valid_i && ocupado_o && !listo_o) begin
                if (MSB_FIRST) begin
                    palabra_o <= {palabra_o[N_BITS-2:0], bit_i};
                end else begin
                    case (count)
                        0:  palabra_o[0]  <= bit_i;
                        1:  palabra_o[1]  <= bit_i;
                        2:  palabra_o[2]  <= bit_i;
                        3:  palabra_o[3]  <= bit_i;
                        4:  palabra_o[4]  <= bit_i;
                        5:  palabra_o[5]  <= bit_i;
                        6:  palabra_o[6]  <= bit_i;
                        7:  palabra_o[7]  <= bit_i;
                        8:  palabra_o[8]  <= bit_i;
                        9:  palabra_o[9]  <= bit_i;
                        default: /* expandir si N_BITS>10 */;
                    endcase
                end

                // avanzar conteo
                count <= count + {{(IDXW-1){1'b0}}, 1'b1};
                idx_o <= count + {{(IDXW-1){1'b0}}, 1'b1};

                if (count == N_BITS-1) begin
                    ocupado_o <= 1'b0;
                    listo_o   <= 1'b1;
                end
            end
        end
    end
endmodule
