
#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

# period defs
set clk_20_period         50.000
set clk_50_period         20.000
set hdmi_clk_1080p_period  6.698

# cpu clk
set cpu_clk_input [get_ports {SYS_CLOCK_50}]
create_clock -name SYS_CLK50 -period $clk_50_period $cpu_clk_input

# d8m clocks
set mipi_base_clk_input [get_ports {D8M_CLOCK_50}]
create_clock -name MIPI_CLK_BASE -period $clk_50_period $mipi_base_clk_input

# mipi clock
set mipi_clk_input [get_ports {MIPI_PIXEL_CLK}]
create_clock -name MIPI_CLK50 -period $clk_50_period $mipi_clk_input

# hdmi clocks
set hdmi_clk_input [get_ports {HDMI_CLOCK_p}]
create_clock -name {HDMI_1080P_CLK} -period $hdmi_clk_1080p_period $hdmi_clk_input

# for enhancing USB BlasterII to be reliable
set tck_period 40
set tck_period_fourth [expr $tck_period/4]
set tck_period_half [expr $tck_period/2]
create_clock -name {altera_reserved_tck} -period $tck_period {altera_reserved_tck}

# unused
create_clock -name CLK_1_UNUSED -period $clk_50_period [get_ports {CLOCK_B7A}]
create_clock -name CLK_2_UNUSED -period $clk_50_period [get_ports {CLOCK_B8A}]


#**************************************************************
# Create Generated Clock
#**************************************************************

# hdmi output
set vclk_out [get_ports {HDMI_TX_CLK}]
create_generated_clock -name {HDMI_1080P_CLK_out} -source $hdmi_clk_input -master_clock {HDMI_1080P_CLK} $vclk_out

# d8m camera
set d8m_pll_clock_out_pin [get_nets {c5g_clk_rst_housekeeping_u|d8m_pll_u|d8m_pll_inst|altera_pll_i|outclk_wire[0]}]
set mipi_refclk_output [get_ports {MIPI_REFCLK}]
create_generated_clock -name {MIPI_CLK20_int} -source $mipi_base_clk_input -divide_by 5 -multiply_by 2 $d8m_pll_clock_out_pin
create_generated_clock -name {MIPI_CLK20_out} -source $d8m_pll_clock_out_pin $mipi_refclk_output

# d8m mipi input gate
set d8m_mipi_clk_gate_out_pin [get_pins {c5g_clk_rst_housekeeping_u|d8m_mipi_clk_gate_u|altclkctrl_0|d8m_mipi_clk_gate_altclkctrl_0_sub_component|sd1|outclk}]
set d8m_mipi_pll_clock_out_pin [get_nets {c5g_clk_rst_housekeeping_u|d8m_mipi_pll_u|d8m_mipi_pll_inst|altera_pll_i|outclk_wire[0]}]
create_generated_clock -name {MIPI_CLK50_gated} -source $mipi_clk_input $d8m_mipi_clk_gate_out_pin
create_generated_clock -name {MIPI_CLK50_int} -source $d8m_mipi_clk_gate_out_pin -divide_by 1 -multiply_by 1 -phase 180 $d8m_mipi_pll_clock_out_pin


#**************************************************************
# Set Clock Uncertainty
#**************************************************************

derive_clock_uncertainty


#**************************************************************
# Set Input Delay
#**************************************************************
set mipi_br_data_delay_min  1.0
set mipi_br_data_delay_max  1.0

set_input_delay -clock MIPI_CLK50 -min $mipi_br_data_delay_min [get_ports {MIPI_PIXEL_D[*] MIPI_PIXEL_HS MIPI_PIXEL_VS}]
set_input_delay -clock MIPI_CLK50 -max $mipi_br_data_delay_max [get_ports {MIPI_PIXEL_D[*] MIPI_PIXEL_HS MIPI_PIXEL_VS}]

#set_input_delay -clock altera_reserved_tck 0 [get_ports altera_reserved_tdi]
#set_input_delay -clock altera_reserved_tck 0 [get_ports altera_reserved_tms]
set_input_delay -clock altera_reserved_tck $tck_period_fourth [get_ports altera_reserved_tdi]
set_input_delay -clock altera_reserved_tck $tck_period_fourth [get_ports altera_reserved_tms]
#set_input_delay -clock altera_reserved_tck $tck_period_half [get_ports altera_reserved_tdi]
#set_input_delay -clock altera_reserved_tck $tck_period_half [get_ports altera_reserved_tms]


#**************************************************************
# Set Output Delay
#**************************************************************

set adv_vtsu 1.0
set adv_vth  0.7
set adv_pcb_data2clk_skew_min 0.0
set adv_pcb_data2clk_skew_max 0.1
set adv_out_dly_max [expr $adv_vtsu + $adv_pcb_data2clk_skew_min]
set adv_out_dly_min [expr -$adv_vth - $adv_pcb_data2clk_skew_max]

set adv_vid_ports [get_ports {HDMI_TX_D[*] HDMI_TX_DE HDMI_TX_HS HDMI_TX_VS}]

set_output_delay -clock {HDMI_1080P_CLK_out} -max $adv_out_dly_max $adv_vid_ports
set_output_delay -clock {HDMI_1080P_CLK_out} -min $adv_out_dly_min $adv_vid_ports

#set_output_delay -clock altera_reserved_tck 0 [get_ports altera_reserved_tdo]
set_output_delay -clock altera_reserved_tck $tck_period_fourth [get_ports altera_reserved_tdo]
#set_output_delay -clock altera_reserved_tck $tck_period_half [get_ports altera_reserved_tdo]

#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -logically_exclusive \
                    -group {CLK_1_UNUSED} \
                    -group {CLK_2_UNUSED} \
                    -group {SYS_CLK50} \
                    -group {MIPI_CLK_BASE} \
                    -group {MIPI_CLK20_int MIPI_CLK20_out} \
                    -group {MIPI_CLK50 MIPI_CLK50_gated MIPI_CLK50_int} \
                    -group {HDMI_1080P_CLK HDMI_1080P_CLK_out}


#**************************************************************
# Set False Paths
#**************************************************************

set_false_path -from [get_ports {CPU_RESET_n KEY[*] SW[*]}]
set_false_path -from [get_ports {CAMERA_I2C_SCL CAMERA_I2C_SDA}]
set_false_path -from [get_ports {MIPI_I2C_SCL MIPI_I2C_SDA}]
set_false_path -from [get_ports {HDMI_TX_INT}]
set_false_path -from [get_ports {I2C_SCL I2C_SDA}]

set_false_path -to [get_ports {LEDG[*] LEDR[*]}]
set_false_path -to [get_ports {HEX0[*] HEX1[*]}]
set_false_path -to [get_ports {CAMERA_I2C_SCL CAMERA_I2C_SDA CAMERA_PWDN_n}]
set_false_path -to [get_ports {MIPI_CS_n MIPI_I2C_SCL MIPI_I2C_SDA MIPI_MCLK MIPI_RESET_n}]
set_false_path -to [get_ports {I2C_SCL I2C_SDA}]


#**************************************************************
# Set False Paths for unused ports
#**************************************************************

set_false_path -from [get_ports {SRAM_D[*]}]
set_false_path -from [get_ports {SD_CMD SD_DAT[*]}]
set_false_path -from [get_ports {ADC_SDO}]
set_false_path -from [get_ports {UART_RX}]
set_false_path -from [get_ports {AUD_ADCDAT AUD_ADCLRCK AUD_BCLK AUD_DACLRCK}]

set_false_path -to [get_ports {SRAM_A[*] SRAM_CE_n SRAM_D[*] SRAM_LB_n SRAM_OE_n SRAM_UB_n SRAM_WE_n}]
set_false_path -to [get_ports {SD_CLK SD_CMD SD_DAT[*]}]
set_false_path -to [get_ports {ADC_CONVST ADC_SCK ADC_SDI}]
set_false_path -to [get_ports {UART_TX}]
set_false_path -to [get_ports {AUD_ADCLRCK AUD_BCLK AUD_DACDAT AUD_DACLRCK AUD_XCK}]
