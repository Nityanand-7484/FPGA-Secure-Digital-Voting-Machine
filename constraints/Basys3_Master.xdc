## ============================================================================
## Constraints file: Basys3_Master.xdc
## Target Board: Digilent Basys 3 (XC7A35T-1CPG236C)
## Project: FPGA-Based Secure Digital Voting Machine
## ============================================================================

## Clock signal (100 MHz)
set_property PACKAGE_PIN W5 [get_ports clk]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Switches
## SW0 to SW3: 4-bit Passcode (auth_code)
set_property PACKAGE_PIN V17 [get_ports {auth_code[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {auth_code[0]}]
set_property PACKAGE_PIN V16 [get_ports {auth_code[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {auth_code[1]}]
set_property PACKAGE_PIN W16 [get_ports {auth_code[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {auth_code[2]}]
set_property PACKAGE_PIN W17 [get_ports {auth_code[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {auth_code[3]}]

## SW4 to SW7: Candidate Selection Buttons / Switches
set_property PACKAGE_PIN W15 [get_ports {candidate_btn[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {candidate_btn[0]}]
set_property PACKAGE_PIN V15 [get_ports {candidate_btn[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {candidate_btn[1]}]
set_property PACKAGE_PIN W14 [get_ports {candidate_btn[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {candidate_btn[2]}]
set_property PACKAGE_PIN W13 [get_ports {candidate_btn[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {candidate_btn[3]}]

## SW15: Admin Mode Switch
set_property PACKAGE_PIN R2 [get_ports admin_mode]					
	set_property IOSTANDARD LVCMOS33 [get_ports admin_mode]

## LEDs (Status Indicators)
set_property PACKAGE_PIN U16 [get_ports {status_led[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {status_led[0]}]
set_property PACKAGE_PIN E19 [get_ports {status_led[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {status_led[1]}]
set_property PACKAGE_PIN U19 [get_ports {status_led[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {status_led[2]}]
set_property PACKAGE_PIN V19 [get_ports {status_led[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {status_led[3]}]

## 7 Segment Display Cathodes (seg[6:0] -> CA..CG)
set_property PACKAGE_PIN W7 [get_ports {seg[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]
set_property PACKAGE_PIN W6 [get_ports {seg[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]
set_property PACKAGE_PIN U8 [get_ports {seg[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]
set_property PACKAGE_PIN V8 [get_ports {seg[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]
set_property PACKAGE_PIN U5 [get_ports {seg[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]
set_property PACKAGE_PIN V5 [get_ports {seg[5]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]
set_property PACKAGE_PIN U7 [get_ports {seg[6]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]

## 7 Segment Display Anodes (an[3:0])
set_property PACKAGE_PIN U2 [get_ports {an[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]
set_property PACKAGE_PIN U4 [get_ports {an[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]
set_property PACKAGE_PIN V4 [get_ports {an[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]
set_property PACKAGE_PIN W4 [get_ports {an[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]

## Push Buttons
## Center Button: Master Reset
set_property PACKAGE_PIN U18 [get_ports reset]						
	set_property IOSTANDARD LVCMOS33 [get_ports reset]
## Up Button: Enter / Authenticate
set_property PACKAGE_PIN T18 [get_ports auth_enter]						
	set_property IOSTANDARD LVCMOS33 [get_ports auth_enter]
## Right Button: Confirm (YES)
set_property PACKAGE_PIN T17 [get_ports confirm_btn]						
	set_property IOSTANDARD LVCMOS33 [get_ports confirm_btn]
## Left Button: Cancel (NO)
set_property PACKAGE_PIN W19 [get_ports cancel_btn]						
	set_property IOSTANDARD LVCMOS33 [get_ports cancel_btn]
## Down Button: New Session (Officer key)
set_property PACKAGE_PIN U17 [get_ports new_session_btn]						
	set_property IOSTANDARD LVCMOS33 [get_ports new_session_btn]
