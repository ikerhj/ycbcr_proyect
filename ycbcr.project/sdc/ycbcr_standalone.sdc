
#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3


#**************************************************************
# Create Clock
#**************************************************************

create_clock -name SYS_CLK -period 6.060 [get_ports {clk}]


#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -clock SYS_CLK -min 0.0 [get_ports {pixel_in_p*}]
set_input_delay -clock SYS_CLK -max 1.0 [get_ports {pixel_in_p*}]


#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -clock SYS_CLK -max 1.0 [get_ports {pixel_out_p*}]
set_output_delay -clock SYS_CLK -min -1.0 [get_ports {pixel_out_p*}]


#**************************************************************
# Set False Paths
#**************************************************************

set_false_path -from [get_ports {nrst}]
