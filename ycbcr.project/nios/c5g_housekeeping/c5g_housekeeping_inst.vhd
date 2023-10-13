	component c5g_housekeeping is
		port (
			camera_pwdn_n_export           : out std_logic;                                        -- export
			clk_clk                        : in  std_logic                     := 'X';             -- clk
			cpu_sync_in_export             : in  std_logic                     := 'X';             -- export
			hw_info_in_export              : in  std_logic_vector(15 downto 0) := (others => 'X'); -- export
			i2c_device_select_export       : out std_logic_vector(1 downto 0);                     -- export
			i2c_master_scl_pad_i_export    : in  std_logic                     := 'X';             -- export
			i2c_master_scl_pad_o_export    : out std_logic;                                        -- export
			i2c_master_scl_padoen_export   : out std_logic;                                        -- export
			i2c_master_sda_pad_i_export    : in  std_logic                     := 'X';             -- export
			i2c_master_sda_pad_o_export    : out std_logic;                                        -- export
			i2c_master_sda_padoen_o_export : out std_logic;                                        -- export
			interrupts_n_export            : in  std_logic                     := 'X';             -- export
			mipi_reset_n_export            : out std_logic;                                        -- export
			n_use_rgb2ycbcr_in_export      : in  std_logic                     := 'X';             -- export
			pll_lock_states_export         : in  std_logic                     := 'X';             -- export
			rst_reset_n                    : in  std_logic                     := 'X'              -- reset_n
		);
	end component c5g_housekeeping;

	u0 : component c5g_housekeeping
		port map (
			camera_pwdn_n_export           => CONNECTED_TO_camera_pwdn_n_export,           --           camera_pwdn_n.export
			clk_clk                        => CONNECTED_TO_clk_clk,                        --                     clk.clk
			cpu_sync_in_export             => CONNECTED_TO_cpu_sync_in_export,             --             cpu_sync_in.export
			hw_info_in_export              => CONNECTED_TO_hw_info_in_export,              --              hw_info_in.export
			i2c_device_select_export       => CONNECTED_TO_i2c_device_select_export,       --       i2c_device_select.export
			i2c_master_scl_pad_i_export    => CONNECTED_TO_i2c_master_scl_pad_i_export,    --    i2c_master_scl_pad_i.export
			i2c_master_scl_pad_o_export    => CONNECTED_TO_i2c_master_scl_pad_o_export,    --    i2c_master_scl_pad_o.export
			i2c_master_scl_padoen_export   => CONNECTED_TO_i2c_master_scl_padoen_export,   --   i2c_master_scl_padoen.export
			i2c_master_sda_pad_i_export    => CONNECTED_TO_i2c_master_sda_pad_i_export,    --    i2c_master_sda_pad_i.export
			i2c_master_sda_pad_o_export    => CONNECTED_TO_i2c_master_sda_pad_o_export,    --    i2c_master_sda_pad_o.export
			i2c_master_sda_padoen_o_export => CONNECTED_TO_i2c_master_sda_padoen_o_export, -- i2c_master_sda_padoen_o.export
			interrupts_n_export            => CONNECTED_TO_interrupts_n_export,            --            interrupts_n.export
			mipi_reset_n_export            => CONNECTED_TO_mipi_reset_n_export,            --            mipi_reset_n.export
			n_use_rgb2ycbcr_in_export      => CONNECTED_TO_n_use_rgb2ycbcr_in_export,      --      n_use_rgb2ycbcr_in.export
			pll_lock_states_export         => CONNECTED_TO_pll_lock_states_export,         --         pll_lock_states.export
			rst_reset_n                    => CONNECTED_TO_rst_reset_n                     --                     rst.reset_n
		);

