// ==========================================================
// Traceback_K3  (solo FLUSH, guarda pred y u)
// ==========================================================
module Traceback_K3 #(
    parameter integer DEPTH = 50,
    parameter integer L     = 20
)(
    input  wire        clk,
    input  wire        rst,

    input  wire        wr_en_i,       // write por paso válido (real o padding)
    input  wire        flush_i,       // mantener alto para drenar
    input  wire [7:0]  surv_pred_i,   // {pred[D], pred[C], pred[B], pred[A]}
    input  wire [3:0]  surv_u_i,      // {u[D], u[C], u[B], u[A]}
    input  wire [1:0]  end_state_i,   // estado final (mínimo global)

    output reg         valido_o,
    output reg         bit_o
);
    // Memorias circulares
    reg [7:0] mem_pred [0:DEPTH-1];
    reg [3:0] mem_u    [0:DEPTH-1];

    reg [$clog2(DEPTH)-1:0]   wr_ptr;
    reg [$clog2(DEPTH+1)-1:0] filled;

    reg [$clog2(DEPTH)-1:0] wr_ptr_last_q;
    reg [1:0]               end_state_last_q;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0; filled <= 0; wr_ptr_last_q <= 0; end_state_last_q <= 2'd0;
        end else if (wr_en_i) begin
            mem_pred[wr_ptr] <= surv_pred_i;
            mem_u[wr_ptr]    <= surv_u_i;
            wr_ptr_last_q    <= wr_ptr;
            end_state_last_q <= end_state_i;
            wr_ptr           <= (wr_ptr==DEPTH-1) ? 0 : (wr_ptr+1);
            if (filled != DEPTH) filled <= filled + 1'b1;
        end
    end

    function [1:0] get_pred; input [7:0] pack_pred; input [1:0] s;
        begin
            case (s)
              2'd0: get_pred = pack_pred[1:0];
              2'd1: get_pred = pack_pred[3:2];
              2'd2: get_pred = pack_pred[5:4];
              default: get_pred = pack_pred[7:6];
            endcase
        end
    endfunction

    function get_u; input [3:0] pack_u; input [1:0] s;
        begin get_u = pack_u[s]; end
    endfunction

    // FSM FLUSH
    localparam IDLE=2'd0, PREP_FLUSH=2'd1, EMIT=2'd2;
    reg [1:0]               state_q, state_d;
    reg [$clog2(DEPTH)-1:0] tb_ptr_q, tb_ptr_d;
    reg [1:0]               tb_state_q, tb_state_d;
    reg                     valido_d, bit_d;

    always @* begin
        state_d    = state_q;
        tb_ptr_d   = tb_ptr_q;
        tb_state_d = tb_state_q;
        valido_d   = 1'b0;
        bit_d      = 1'b0;

        case (state_q)
            IDLE:
                if (flush_i && (filled != 0)) state_d = PREP_FLUSH;

            PREP_FLUSH: begin
                tb_ptr_d   = wr_ptr_last_q;    // último índice escrito
                tb_state_d = end_state_last_q; // estado final
                state_d    = EMIT;
            end

            EMIT: begin
                bit_d    = get_u(mem_u[tb_ptr_q], tb_state_q);
                valido_d = 1'b1;

                tb_state_d = get_pred(mem_pred[tb_ptr_q], tb_state_q);
                tb_ptr_d   = (tb_ptr_q==0) ? (DEPTH-1) : (tb_ptr_q-1);

                state_d    = flush_i ? EMIT : IDLE;
            end
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_q<=IDLE; tb_ptr_q<=0; tb_state_q<=2'd0;
            valido_o<=1'b0; bit_o<=1'b0;
        end else begin
            state_q    <= state_d;
            tb_ptr_q   <= tb_ptr_d;
            tb_state_q <= tb_state_d;
            valido_o   <= valido_d;
            bit_o      <= bit_d;
        end
    end
endmodule
