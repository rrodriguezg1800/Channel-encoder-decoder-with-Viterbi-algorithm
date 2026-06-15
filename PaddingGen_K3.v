module PaddingGen_K3 #(
    parameter integer DATA_BITS = 10,
    parameter integer PAD_STEPS = 22
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             par_valido_i,
    input  wire [1:0]       dec_in_i,
    input  wire [$clog2(DATA_BITS):0] step_cnt_i,

    output wire             wr_en_step_o,
    output wire [1:0]       dec_in_eff_o,
    output reg              pad_active_o,
    output reg [$clog2(PAD_STEPS+1)-1:0] pad_cnt_o
);

    // Activación de padding justo después del último par real
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pad_active_o <= 1'b0;
            pad_cnt_o    <= 0;
        end else begin
            if (par_valido_i && (step_cnt_i == DATA_BITS-1)) begin
                pad_active_o <= 1'b1;
                pad_cnt_o    <= PAD_STEPS[$clog2(PAD_STEPS+1)-1:0];
            end

            if (pad_active_o && (par_valido_i || pad_active_o)) begin
                if (pad_cnt_o == 1) pad_active_o <= 1'b0;
                pad_cnt_o <= pad_cnt_o - 1'b1;
            end
        end
    end

    // Multiplexor de entrada efectiva
    assign dec_in_eff_o  = pad_active_o ? 2'b00 : dec_in_i;
    assign wr_en_step_o  = par_valido_i | pad_active_o;

endmodule
