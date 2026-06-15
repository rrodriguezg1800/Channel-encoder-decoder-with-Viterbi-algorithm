module MetricSelector_K3 (
    input  wire [5:0] mA, mB, mC, mD,
    input  wire       enA, enB, enC, enD,
    output wire [1:0] min_state_o,
    output wire [5:0] min_metric_o
);

    reg [5:0] min_val;
    reg [1:0] min_state;

    always @* begin
        min_val   = 6'd63; // INF
        min_state = 2'b00; // A por defecto

        if (enA && mA < min_val) begin min_val = mA; min_state = 2'b00; end
        if (enB && mB < min_val) begin min_val = mB; min_state = 2'b01; end
        if (enC && mC < min_val) begin min_val = mC; min_state = 2'b10; end
        if (enD && mD < min_val) begin min_val = mD; min_state = 2'b11; end
    end

    assign min_state_o  = min_state;
    assign min_metric_o = min_val;
endmodule 
