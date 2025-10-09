# =====================================
# Basys3 Pin Constraints
# =====================================

# ---------- Clock 100MHz ----------
set_property PACKAGE_PIN W5 [get_ports CLK]
set_property IOSTANDARD LVCMOS33 [get_ports CLK]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports CLK]

# ---------- Switches (0-15) ----------
set_property PACKAGE_PIN V17 [get_ports {SW[0]}]
set_property PACKAGE_PIN V16 [get_ports {SW[1]}]
set_property PACKAGE_PIN W16 [get_ports {SW[2]}]
set_property PACKAGE_PIN W17 [get_ports {SW[3]}]
set_property PACKAGE_PIN W15 [get_ports {SW[4]}]
set_property PACKAGE_PIN V15 [get_ports {SW[5]}]
set_property PACKAGE_PIN W14 [get_ports {SW[6]}]
set_property PACKAGE_PIN W13 [get_ports {SW[7]}]
set_property PACKAGE_PIN V2  [get_ports {SW[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[*]}]

# ---------- LEDs (0-7) para resultado ----------
set_property PACKAGE_PIN U16 [get_ports {LED[0]}]
set_property PACKAGE_PIN E19 [get_ports {LED[1]}]
set_property PACKAGE_PIN U19 [get_ports {LED[2]}]
set_property PACKAGE_PIN V19 [get_ports {LED[3]}]
set_property PACKAGE_PIN W18 [get_ports {LED[4]}]
set_property PACKAGE_PIN U15 [get_ports {LED[5]}]
set_property PACKAGE_PIN U14 [get_ports {LED[6]}]
set_property PACKAGE_PIN V14 [get_ports {LED[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[*]}]

# ---------- LEDs para flags (L1 y P1 son LED14 y LED15) ----------
set_property PACKAGE_PIN L1  [get_ports LED_ZERO]     ;# LED14 - Flag Zero
set_property PACKAGE_PIN P1  [get_ports LED_CARRY]    ;# LED15 - Flag Carry
set_property IOSTANDARD LVCMOS33 [get_ports {LED_ZERO LED_CARRY}]

# ---------- Botones ----------
set_property PACKAGE_PIN W19 [get_ports BTN_A]        ;# Left button
set_property PACKAGE_PIN T17 [get_ports BTN_B]        ;# Right button  
set_property PACKAGE_PIN T18 [get_ports BTN_OP]       ;# Up button
set_property PACKAGE_PIN U18 [get_ports BTN_RESET]    ;# Center button (RESET)
set_property IOSTANDARD LVCMOS33 [get_ports {BTN_A BTN_B BTN_OP BTN_RESET}]



