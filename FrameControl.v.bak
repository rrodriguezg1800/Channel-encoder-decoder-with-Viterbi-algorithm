// ==========================================================
// Módulo: FrameControl
// Controla el avance de trama, disparo de flush y reconstrucción de bits decodificados.
// - step_cnt_o avanza hasta TOTAL_STEPS
// - flush_o se activa al final para reconstruir los DATA_BITS reales
// - salto de padding mediante skip_cnt_q
// - salida_final_o se reconstruye MSB→LSB
// ==========================================================

module FrameControl #(
    parameter DATA_BITS   = 10,   // Bits reales de datos
    parameter PAD_STEPS   = 22,   // Padding para permitir traceback completo
    parameter TOTAL_STEPS = 32    // DATA_BITS + PAD_STEPS
)(
    input  wire clk,
    input  wire rst,
    input  wire wr_en_step,       // Habilita avance de paso
    input  wire tb_valido_i,      // Bit válido desde traceback
    input  wire tb_bit_i,         // Bit decodificado desde traceback

    output reg flush_o,           // Señal para iniciar reconstrucción
    output reg bit_decod_o,       // Bit decodificado actual
    output reg [DATA_BITS-1:0] salida_final_o, // Palabra reconstruida
    output reg listo_o,           // Señal de salida completa
    output reg [$clog2(TOTAL_STEPS):0] step_cnt_o // Contador de pasos
);

    // Contador de bits reconstruidos
    reg [$clog2(DATA_BITS):0] out_cnt_q;

    // Armado y disparo de flush
    reg flush_arm_q;

    // Contador para saltar padding inicial
    reg [$clog2(PAD_STEPS+1)-1:0] skip_cnt_q;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Inicialización de registros
            step_cnt_o     <= 0;
            flush_arm_q    <= 0;
            flush_o        <= 0;
            skip_cnt_q     <= 0;
            out_cnt_q      <= 0;
            bit_decod_o    <= 0;
            salida_final_o <= 0;
            listo_o        <= 0;
        end else begin
            // Avance de trama si hay paso válido
            if (wr_en_step) begin
                if (step_cnt_o < TOTAL_STEPS)
                    step_cnt_o <= step_cnt_o + 1;

                // Preparar flush al final de la trama
                if (step_cnt_o == TOTAL_STEPS-1)
                    flush_arm_q <= 1;
            end

            // Disparo de flush: saltar padding
            if (flush_arm_q) begin
                flush_o     <= 1;
                flush_arm_q <= 0;
                skip_cnt_q  <= PAD_STEPS;
            end

            // Reconstrucción de bits decodificados
            if (flush_o && tb_valido_i) begin
                if (skip_cnt_q != 0) begin
                    // Saltar padding
                    skip_cnt_q <= skip_cnt_q - 1;
                end else if (out_cnt_q < DATA_BITS) begin
                    // Guardar bit decodificado
                    bit_decod_o    <= tb_bit_i;
                    salida_final_o <= {tb_bit_i, salida_final_o[DATA_BITS-1:1]};
                    out_cnt_q      <= out_cnt_q + 1;

                    // Señal de salida lista
                    if (out_cnt_q == DATA_BITS-1) begin
                        listo_o <= 1;
                        flush_o <= 0; // Fin de reconstrucción
                    end else begin
                        listo_o <= 0;
                    end
                end
            end else begin
                listo_o <= 0;
            end
        end
    end
endmodule 
