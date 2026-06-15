transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError {C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError/Top_TX.v}
vlog -vlog01compat -work work +incdir+C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError {C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError/CodConv3.v}
vlog -vlog01compat -work work +incdir+C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError {C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError/divisor_frecuencia_v3.v}
vlog -vlog01compat -work work +incdir+C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError {C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError/Entrada_8bits.v}
vlog -vlog01compat -work work +incdir+C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError {C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError/Ruido_Pares20.v}
vlog -vlog01compat -work work +incdir+C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError {C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError/Top_RX.v}
vlog -vlog01compat -work work +incdir+C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError {C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError/Top_Decod_Viterbi_K3.v}
vlog -vlog01compat -work work +incdir+C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError {C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError/Decod_Viterbi_K3.v}
vlog -vlog01compat -work work +incdir+C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError {C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError/HammingGen_K3.v}
vlog -vlog01compat -work work +incdir+C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError {C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError/PaddingGen_K3.v}
vlog -vlog01compat -work work +incdir+C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError {C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError/MetricSelector_K3.v}
vlog -vlog01compat -work work +incdir+C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError {C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError/Traceback_K3.v}
vlog -vlog01compat -work work +incdir+C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError {C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError/Top_EncDec_BitsError.v}
vlog -vlog01compat -work work +incdir+C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError {C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError/ACS_K3.v}
vlog -vlog01compat -work work +incdir+C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError {C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError/FrameControl.v}
vlog -vlog01compat -work work +incdir+C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError {C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError/Acumulador_Sec_Erronea.v}
vlog -vlog01compat -work work +incdir+C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError {C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError/serializador.v}

vlog -vlog01compat -work work +incdir+C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError/simulation/modelsim {C:/Users/golyp/Documents/ProyectoTerminal_v/OFICIALES/Encoder_Decoder_Inserting_BitsError/simulation/modelsim/Top_EncDec_BitsError.vt}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  Top_EncDec_BitsError_vlg_tst

add wave *
view structure
view signals
run -all
