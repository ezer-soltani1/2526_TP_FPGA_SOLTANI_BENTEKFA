quit -sim

vlib work

vcom encoder.vhd
vcom encoder_tb.vhd

vsim -c work.encoder_tb

# INPUTS
add wave -divider Inputs:
add wave -color blue /dut/i_clk
add wave -color red /dut/i_rst_n
add wave -color green /dut/i_a
add wave -color darkgreen /dut/i_b

# OUTPUTS
add wave -divider Outputs:
add wave -color yellow /dut/o_increment
add wave -color orange /dut/o_decrement

# INTERNAL SIGNALS (optional, for debugging)
add wave -divider Internal:
add wave /dut/s_a_sync
add wave /dut/s_b_sync
add wave /dut/s_a_prev
add wave /dut/s_b_prev
add wave /dut/r_cnt
add wave /dut/s_tick_1ms

run -all
