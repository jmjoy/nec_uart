//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.03 Education 
//Created Time: 2025-11-28 22:54:07
create_clock -name sys_clk -period 20 -waveform {0 10} [get_ports {sys_clk}]
//set_max_delay 5.0 -from [get_registers {*/sync_r0*}] -to [get_registers {*/sync_r1*}]
