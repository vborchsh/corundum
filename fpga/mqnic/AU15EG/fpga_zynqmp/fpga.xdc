# XDC constraints for the Alinx AU15EG board
# part: xczu15eg-ffvb1156-2-i

# General configuration
set_property BITSTREAM.GENERAL.COMPRESS true [current_design]

# LEDs
set_property -dict {LOC AP12 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led[0]}]
set_property -dict {LOC AM13 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports {led[1]}]

set_false_path -to [get_ports {led[*]}]
set_output_delay 0.000 [get_ports {led[*]}]

# SFP+ Interface
set_property -dict {LOC M2} [get_ports sfp0_rx_p]
set_property -dict {LOC M1} [get_ports sfp0_rx_n]
set_property -dict {LOC N4} [get_ports sfp0_tx_p]
set_property -dict {LOC N3} [get_ports sfp0_tx_n]
set_property -dict {LOC T2} [get_ports sfp1_rx_p]
set_property -dict {LOC T1} [get_ports sfp1_rx_n]
set_property -dict {LOC R4} [get_ports sfp1_tx_p]
set_property -dict {LOC R3} [get_ports sfp1_tx_n]
set_property -dict {LOC L8} [get_ports sfp_mgt_refclk_0_p]
set_property -dict {LOC L7} [get_ports sfp_mgt_refclk_0_n]
set_property -dict {LOC G13 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports sfp0_tx_disable_b]
set_property -dict {LOC J12 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 8} [get_ports sfp1_tx_disable_b]

# 125 MHz MGT reference clock
create_clock -period 8.000 -name sfp_mgt_refclk_0 [get_ports sfp_mgt_refclk_0_p]

set_false_path -to [get_ports {sfp0_tx_disable_b sfp1_tx_disable_b}]
set_output_delay 0.000 [get_ports {sfp0_tx_disable_b sfp1_tx_disable_b}]
