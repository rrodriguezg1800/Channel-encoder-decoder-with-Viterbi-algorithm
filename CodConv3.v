module CodConv3 #(
    parameter integer K = 3,
    parameter integer N = 8,
    parameter [5:0]  RESPUESTA = 6'b111011,
    // -------- pares de guarda al final --------
    parameter integer GUARD_PAIRS = 1          // 10 + 1 = 11 pares => 22 bits
)(
    input  wire clk,
    input  wire rst,
    input  wire iniciar,
    input  wire [7:0] mensaje,
    output reg  salida1_o,   // G1
    output reg  salida2_o,   // G2
    output reg  listo_o,
    output reg  par_valid_o,
    output reg [2*((N+K-1)+GUARD_PAIRS)-1:0] codigo_o_acumulado
);
    localparam integer REAL_STEPS  = (N + K - 1);              // 10
    localparam integer TOTAL_PAIRS = REAL_STEPS + GUARD_PAIRS; // 11
    localparam integer CNTW        = $clog2(TOTAL_PAIRS+1);    // cuenta 0..11

    reg [K-1:0]  shift_reg;
    reg [CNTW-1:0] contador;     // 0..11
    reg          transmitiendo;
    reg [N-1:0]  mensaje_invertido;

    wire [K-1:0] G1 = {RESPUESTA[5], RESPUESTA[3], RESPUESTA[1]};
    wire [K-1:0] G2 = {RESPUESTA[4], RESPUESTA[2], RESPUESTA[0]};

    function automatic parity;
        input [K-1:0] data;
        input [K-1:0] gen;
        integer i;
        begin
            parity = 1'b0;
            for (i = 0; i < K; i = i + 1)
                parity = parity ^ (data[i] & gen[i]);
        end
    endfunction

    integer i;
    reg entrada_actual;
    reg t1, t2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg          <= {K{1'b0}};
            contador           <= {CNTW{1'b0}};
            transmitiendo      <= 1'b0;
            listo_o            <= 1'b0;
            par_valid_o        <= 1'b0;
            codigo_o_acumulado <= {(2*TOTAL_PAIRS){1'b0}};
            salida1_o          <= 1'b0;
            salida2_o          <= 1'b0;
            mensaje_invertido  <= {N{1'b0}};
        end else begin
            if (iniciar && !transmitiendo) begin
                // invertir MSB->LSB
                for (i = 0; i < N; i = i + 1)
                    mensaje_invertido[i] <= mensaje[N-1-i];
                transmitiendo <= 1'b1;
                contador      <= {CNTW{1'b0}};
                listo_o       <= 1'b0;
            end else if (transmitiendo && !listo_o) begin
                // 0..N-1 => bits del mensaje; N..REAL_STEPS-1 => cola 0; luego GUARD_PAIRS => 0
                if (contador < N)
                    entrada_actual = mensaje_invertido[contador];
                else
                    entrada_actual = 1'b0; // cola y guarda en 0

                shift_reg <= {entrada_actual, shift_reg[K-1:1]};
                t1        = parity({entrada_actual, shift_reg[K-1:1]}, G1);
                t2        = parity({entrada_actual, shift_reg[K-1:1]}, G2);

                salida1_o <= t1;
                salida2_o <= t2;

                if (contador < TOTAL_PAIRS) begin
                    // Guardar G1,G2 MSB→LSB en 11 pares
                    codigo_o_acumulado[2*(TOTAL_PAIRS-1-contador)+1] <= t1;
                    codigo_o_acumulado[2*(TOTAL_PAIRS-1-contador)  ] <= t2;
                end

                par_valid_o <= (contador < TOTAL_PAIRS);
                contador    <= contador + 1'b1;

                // listo tras completar el último par (se aserta en el siguiente ciclo de reloj)
                if (contador == TOTAL_PAIRS) begin
                    listo_o       <= 1'b1;
                    transmitiendo <= 1'b0;
                    par_valid_o   <= 1'b0;
                end
            end else begin
                par_valid_o <= 1'b0;
            end
        end
    end
endmodule
