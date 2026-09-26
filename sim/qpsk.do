transcript on

if {[file exists work]} {
    vdel -all
}

vlib work

vcom -2008 ../rtl/qpsk_pkg.vhd
vcom -2008 ../rtl/cosine_generator.vhd
vcom -2008 ../rtl/low_pass_filter.vhd
vcom -2008 ../rtl/qpsk_modulator.vhd
vcom -2008 ../rtl/simulated_channel.vhd
vcom -2008 ../rtl/qpsk_demodulator.vhd
vcom -2008 ../rtl/qpsk_system.vhd
vcom -2008 ../tb/tb_qpsk_system.vhd

vsim -voptargs=+acc work.tb_qpsk_system

add wave -divider "CLOCK / CONTROL"
add wave sim:/tb_qpsk_system/clk
add wave sim:/tb_qpsk_system/reset
add wave sim:/tb_qpsk_system/sample_ce

add wave -divider "TRANSMITTER"
add wave -radix binary sim:/tb_qpsk_system/tx_bits_debug
add wave -radix binary sim:/tb_qpsk_system/tx_symbol_bits
add wave sim:/tb_qpsk_system/tx_symbol_valid
add wave -signed -radix decimal sim:/tb_qpsk_system/tx_i
add wave -signed -radix decimal sim:/tb_qpsk_system/tx_q
add wave -signed -radix decimal sim:/tb_qpsk_system/tx_rf

add wave -divider "CHANNEL"
add wave -signed -radix decimal sim:/tb_qpsk_system/rx_rf

add wave -divider "RECEIVER MIXER"
add wave -signed -radix decimal sim:/tb_qpsk_system/rx_mixed_i
add wave -signed -radix decimal sim:/tb_qpsk_system/rx_mixed_q

add wave -divider "RECEIVER BASEBAND"
add wave -signed -radix decimal sim:/tb_qpsk_system/rx_i
add wave -signed -radix decimal sim:/tb_qpsk_system/rx_q

add wave -divider "RECEIVED BITS"
add wave -radix binary sim:/tb_qpsk_system/rx_bits
add wave sim:/tb_qpsk_system/rx_bits_valid

configure wave -namecolwidth 220
configure wave -valuecolwidth 120
configure wave -timelineunits ns

run 0.1 ms

wave zoom full
