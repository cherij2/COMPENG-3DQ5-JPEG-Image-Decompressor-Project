# activate waveform simulation

view wave

# format signal names in waveform

configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits us

# add signals to waveform

add wave -divider -height 20 {Top-level signals}
add wave -bin UUT/CLOCK_50_I
add wave -bin UUT/resetn
add wave UUT/top_state
add wave -uns UUT/UART_timer

add wave -divider -height 10 {SRAM signals}
add wave -uns UUT/SRAM_address
add wave -hex UUT/SRAM_write_data
add wave -bin UUT/SRAM_we_n
add wave -hex UUT/SRAM_read_data

add wave -divider -height 10 {M1 Signals}
#add wave -bin UUT/VGA_unit/VGA_HSYNC_O
#add wave -bin UUT/VGA_unit/VGA_VSYNC_O
#add wave -uns UUT/VGA_unit/pixel_X_pos
#add wave -uns UUT/VGA_unit/pixel_Y_pos
#add wave -hex UUT/VGA_unit/VGA_red
#add wave -hex UUT/VGA_unit/VGA_green
#add wave -hex UUT/VGA_unit/VGA_blue


add wave UUT/Milestone1/M1State

add wave -hex UUT/Milestone1/Shift_Count_U
add wave -hex UUT/Milestone1/Shift_Count_V


add wave -hex UUT/Milestone1/UPrime_Odd
add wave -hex UUT/Milestone1/VPrime_Odd

add wave -hex UUT/Milestone1/Final_UPrime_Odd
add wave -hex UUT/Milestone1/Final_VPrime_Odd
add wave -hex UUT/Milestone1/Final_UPrime_Even
add wave -hex UUT/Milestone1/Final_VPrime_Even

