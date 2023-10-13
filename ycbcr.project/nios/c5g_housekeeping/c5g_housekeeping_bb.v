
module c5g_housekeeping (
	camera_pwdn_n_export,
	clk_clk,
	cpu_sync_in_export,
	hw_info_in_export,
	i2c_device_select_export,
	i2c_master_scl_pad_i_export,
	i2c_master_scl_pad_o_export,
	i2c_master_scl_padoen_export,
	i2c_master_sda_pad_i_export,
	i2c_master_sda_pad_o_export,
	i2c_master_sda_padoen_o_export,
	interrupts_n_export,
	mipi_reset_n_export,
	n_use_rgb2ycbcr_in_export,
	pll_lock_states_export,
	rst_reset_n);	

	output		camera_pwdn_n_export;
	input		clk_clk;
	input		cpu_sync_in_export;
	input	[15:0]	hw_info_in_export;
	output	[1:0]	i2c_device_select_export;
	input		i2c_master_scl_pad_i_export;
	output		i2c_master_scl_pad_o_export;
	output		i2c_master_scl_padoen_export;
	input		i2c_master_sda_pad_i_export;
	output		i2c_master_sda_pad_o_export;
	output		i2c_master_sda_padoen_o_export;
	input		interrupts_n_export;
	output		mipi_reset_n_export;
	input		n_use_rgb2ycbcr_in_export;
	input		pll_lock_states_export;
	input		rst_reset_n;
endmodule
