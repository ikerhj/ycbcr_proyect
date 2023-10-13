library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.rtl_cfg.all;
use work.macros.all;

use work.camera2hdmi_pack.all;
use work.ycbcr_pack.all;
use work.d8m_timings.all;
use work.videotimings.all;


entity c5g_camera2hdmi_top is

  port (
    -- CLOCK
    HDMI_CLOCK_p : in std_logic;  -- BANK 4A, configurable (Si5338, CLK2A) used as HDMI clock (e.g. 148.5MHz @ 1080p60)
    SYS_CLOCK_50 : in std_logic;  -- BANK 5B, fixed clock (from X2) used for system
    D8M_CLOCK_50 : in std_logic;  -- BANK 6A, fixed clock (from X2) used for D8M PLL reference
    CLOCK_B7A    : in std_logic;  -- BANK 7A, configurable (Si5338, CLK3A) unused
    CLOCK_B8A    : in std_logic;  -- BANK 8A, configurable (Si5338, CLK3B) unused
    
    -- LEDs, Keys, SWs and SEG7
    LEDG : out std_logic_vector(7 downto 0) := (others => '0');
    LEDR : out std_logic_vector(9 downto 0) := (others => '0');
    
    CPU_RESET_n : in std_logic;
    KEY : in std_logic_vector(3 downto 0);
    
    SW : in std_logic_vector(9 downto 0);
    
    HEX0 : out std_logic_vector(6 downto 0) := (others => '1');
    HEX1 : out std_logic_vector(6 downto 0) := (others => '1');
    
    -- GPIO, GPIO connect to D8M-GPIO
    CAMERA_I2C_SCL : inout std_logic;
    CAMERA_I2C_SDA : inout std_logic;
    CAMERA_PWDN_n : out std_logic := '0';
    MIPI_CS_n : out std_logic := '0';
    MIPI_I2C_SCL : inout std_logic;
    MIPI_I2C_SDA : inout std_logic;
    MIPI_MCLK : out std_logic := '1';
    MIPI_PIXEL_CLK : in std_logic;
    MIPI_PIXEL_D : in std_logic_vector(9 downto 0);
--    MIPI_PIXEL_D : out std_logic_vector(9 downto 0);
    MIPI_PIXEL_HS : in std_logic;
    MIPI_PIXEL_VS : in std_logic;
    MIPI_REFCLK : out std_logic;
    MIPI_RESET_n : out std_logic := '0';

    -- SRAM
    SRAM_A : out std_logic_vector(17 downto 0);
    SRAM_CE_n : out std_logic;
    SRAM_D : inout std_logic_vector(15 downto 0);
    SRAM_LB_n : out std_logic;
    SRAM_OE_n : out std_logic;
    SRAM_UB_n : out std_logic;
    SRAM_WE_n : out std_logic;
    
    -- HDMI-Tx
    HDMI_TX_CLK : out std_logic;  -- BANK 5B
    HDMI_TX_D  : out std_logic_vector(23 downto 0);
    HDMI_TX_DE : out std_logic;
    HDMI_TX_HS : out std_logic;
    HDMI_TX_VS : out std_logic;
    HDMI_TX_INT : in std_logic;
    
    -- I2C for Audio/HDMI-TX/Si5338/HSMC
    I2C_SCL : inout std_logic;
    I2C_SDA : inout std_logic;
    
    -- UNUSED IOs
    -- SD Card
    SD_CLK : out std_logic;
    SD_CMD : inout std_logic;
    SD_DAT : inout std_logic_vector(3 downto 0);
    
    -- ADC SPI @ Arduino
    ADC_CONVST : out std_logic;
    ADC_SCK : out std_logic;
    ADC_SDI : out std_logic;
    ADC_SDO : in std_logic;
    
    -- UART to USB
    UART_RX : in std_logic;
    UART_TX : out std_logic;

    -- Audio
    AUD_ADCDAT : in std_logic;
    AUD_ADCLRCK : inout std_logic;
    AUD_BCLK : inout std_logic;
    AUD_DACDAT : out std_logic;
    AUD_DACLRCK : inout std_logic;
    AUD_XCK : out std_logic
  );

end c5g_camera2hdmi_top;

architecture behavioral of c5g_camera2hdmi_top is

  -- constants
  constant VIDEO_PIPELINE_LENGTH : integer := 4; -- defines the number of processing delays from generating a sync signal until the video output is ready
  constant VIDEO_RGB2YCBCR_PIPELINE_LENGTH : integer := 1;  -- defines the pipeline length of the RGB to YCbCR encoder
  
  -- type declarations  
  type sync_pipeline_t is array (0 to (VIDEO_PIPELINE_LENGTH + VIDEO_RGB2YCBCR_PIPELINE_LENGTH)) of sync_signals_t;

  -- signal for rtl-version
  signal hw_info_s : std_logic_vector((VERSION_MAIN_LENGTH + VERSION_SUB_LENGTH - 1) downto 0);

  -- component declarations
  component c5g_clk_rst_housekeeping is
    port (
      sys_clk_base_i : in std_logic;            -- 50MHz
      sys_arst_n_i : in std_logic;
      sys_clk_o : out std_logic := '0';         -- 50MHz (same as input)
      sys_srst_n_o : out std_logic := '0';
      d8m_clk_base_i : in std_logic;            -- 50MHz
      d8m_arst_n_i : in std_logic;
      d8m_clk_base_o : out std_logic := '0';    -- 20MHz
      d8m_pll_locked_o : out std_logic;
      d8m_srst_n_o : out std_logic := '0';
      d8m_mipi_clk_i : in std_logic;            -- 50MHz
      d8m_mipi_arst_n_i : in std_logic;
      d8m_mipi_clk_o : out std_logic := '0';    -- 50MHz
      d8m_mipi_srst_n_o : out std_logic := '0';
      vid_clk_base_i : in std_logic;            -- e.g. 148.5MHz
      vid_arst_n_i : in std_logic;
      vid_clk_o : out std_logic := '0';         -- e.g. 148.5MHz (same as input)
      vid_srst_n_o : out std_logic := '0'
    );
  end component c5g_clk_rst_housekeeping;
  
  component register_clk_resync is
    generic(
      reg_width : positive := 16;
      resync_stages : positive := 2
      
    );
    port(
      clk_i : in std_logic;
      clk_en_i : in boolean;
      nrst_i : in std_logic;
      reg_preset_i : in std_logic_vector(reg_width-1 downto 0) := (others => '0');
      reg_i : in std_logic_vector(reg_width-1 downto 0);
      reg_o: out std_logic_vector(reg_width-1 downto 0) := (others => '0')
    );
  end component register_clk_resync;

  component c5g_housekeeping is
    port (
      clk_clk                        : in  std_logic                     := 'X';             -- clk
      rst_reset_n                    : in  std_logic                     := 'X';             -- reset_n
      i2c_master_scl_padoen_export   : out std_logic;                                        -- export
      i2c_master_scl_pad_i_export    : in  std_logic                     := 'X';             -- export
      i2c_master_scl_pad_o_export    : out std_logic;                                        -- export
      i2c_master_sda_padoen_o_export : out std_logic;                                        -- export
      i2c_master_sda_pad_i_export    : in  std_logic                     := 'X';             -- export
      i2c_master_sda_pad_o_export    : out std_logic;                                        -- export
      i2c_device_select_export       : out std_logic_vector(1 downto 0);                     -- export
      camera_pwdn_n_export           : out std_logic;                                        -- export
      mipi_reset_n_export            : out std_logic;                                        -- export
      interrupts_n_export            : in  std_logic                     := 'X';             -- export
      pll_lock_states_export         : in  std_logic                     := 'X';             -- export
      n_use_rgb2ycbcr_in_export      : in  std_logic                     := 'X';             -- export
      cpu_sync_in_export             : in  std_logic                     := 'X';             -- export
      hw_info_in_export              : in  std_logic_vector(15 downto 0) := (others => 'X')  -- export
    );
  end component c5g_housekeeping;
  
  component bayer2rgb is
    port (
      clk_i : in std_logic;
      rstn_i : in std_logic;
      hs_i : in std_logic;
      vs_i : in std_logic;
      camera_pixel_i : in std_logic_vector(camera_pixel_depth-1 downto 0);
      hs_o : out std_logic := D8M_HSYNC_ACTIVE_POLARITY_1080P;
      vs_o : out std_logic := D8M_VSYNC_ACTIVE_POLARITY_1080P;
      de_o : out boolean := FALSE;
      rgb_pixel_o : out camera_rgb_pixel_t := (others => to_unsigned(0,camera_pixel_depth))
    );
  end component bayer2rgb;
  
  component sync_gen_1080p is
    port(
      vclk_i : in std_logic;
      rstn_i : in std_logic;
      xpos_o : out natural range 0 to 4095;
      ypos_o : out natural range 0 to 2047;
      hsync_o : out std_logic;
      vsync_o : out std_logic;
      csync_o : out std_logic;
      de_o : out std_logic
    );
  end component sync_gen_1080p;
  
  component testimg is
    generic (
      xscale : natural range 0 to 4 := 4;
      xstart : natural range 0 to 2047 := X_START_1080P;
      xactive : natural range 0 to 2047 := H_ACTIVE_1080P;
      yscale : natural range 0 to 4 := 4;
      ystart : natural range 0 to 2047 := Y_START_1080P;
      yactive : natural range 0 to 2047 := V_ACTIVE_1080P
    );
    port (
      tst_clk_i : in std_logic;
      tst_nrst_i : in std_logic;
      tst_capture_ntrigger_i : in std_logic;
      tst_hs_i : in std_logic;
      tst_vs_i :in std_logic;
      tst_de_i : in boolean;
      tst_rgb_pixel_i :in camera_rgb_pixel_t;
      vclk_i : in std_logic;
      rstn_i : in std_logic;
      xpos_i : in natural range 0 to 4095;
      ypos_i : in natural range 0 to 2047;
      videodata_rgb_o : out camera_rgb_pixel_t := (others => to_unsigned(0,camera_pixel_depth))
    );
  end component testimg;

  component ycbcr_design is
    port (
      nrst : in  std_logic;
      clk : in  std_logic;
      pixel_in : in  rgb_pixel_t;
      pixel_out : out ycbcr_pixel_t
    );
  end component ycbcr_design;

  -- signals
  signal clk_sys_s : std_logic;
  signal sync_cpu_rst_n_s : std_logic;
  
  signal clk_d8m_s : std_logic;
  signal d8m_pll_lock_state_s, sync_d8m_rst_n_s : std_logic;
  
  signal d8m_mipi_clk_s : std_logic;
  signal sync_d8m_mipi_rst_n_s : std_logic;
  
  signal clk_video_s : std_logic;
  signal sync_video_rst_n_s : std_logic;
  
  signal cpu_scl_pad_i, cpu_scl_pad_o, cpu_scl_padoen_o : std_logic;
  signal cpu_sda_pad_i, cpu_sda_pad_o, cpu_sda_padoen_o : std_logic;
  signal cpu_i2c_device_select : std_logic_vector(1 downto 0);
  
  signal videosync_a : sync_pipeline_t;
  signal xpos_s : natural range 0 to 4095 := 0;
  signal ypos_s : natural range 0 to 2047 := 0;
  
  signal cpu_sync_s : std_logic := '0';
  
  signal d8m_rgb_hs_s : std_logic;
  signal d8m_rgb_vs_s : std_logic;
  signal d8m_rgb_de_s : boolean;
  signal d8m_rgb_pixel_s : camera_rgb_pixel_t;
  
  signal d8m_capture_ntrigger_s : std_logic;
  
  signal videodata_rgb_s : camera_rgb_pixel_t;
  signal videodata_rgb_tmp_s : rgb_pixel_t;
  signal videodata_ycbcr_s : ycbcr_pixel_t;
  
  signal n_use_rgb2ycbcr_cpu_s : std_logic;
  signal n_use_rgb2ycbcr_fpga_s : std_logic;
  
  signal videosignal_rgb_s : video_signals_t := (others => (others => '0'));
  signal videosignal_ycbcr_s : video_signals_t := (others => (others => '0'));
  
  -- counter for testing --
  attribute noprune: boolean;
  
  signal d8m_hs_cnt : natural range 0 to 2**D8M_H_CNT_WIDTH-1;
  signal d8m_vs_cnt : natural range 0 to 2**D8M_V_CNT_WIDTH-1;
  
  attribute noprune of d8m_hs_cnt: signal is true;
  attribute noprune of d8m_vs_cnt: signal is true;
  
begin
  
  ------------------
  -- HOUSEKEEPING --
  ------------------
  c5g_clk_rst_housekeeping_u : c5g_clk_rst_housekeeping
    port map (
      sys_clk_base_i => SYS_CLOCK_50,
      sys_arst_n_i => CPU_RESET_n,
      sys_clk_o => clk_sys_s,
      sys_srst_n_o => sync_cpu_rst_n_s,
      d8m_clk_base_i => D8M_CLOCK_50,
      d8m_arst_n_i => KEY(0),
      d8m_clk_base_o => clk_d8m_s,
      d8m_pll_locked_o => d8m_pll_lock_state_s,
      d8m_srst_n_o => sync_d8m_rst_n_s,
      d8m_mipi_clk_i => MIPI_PIXEL_CLK,
      d8m_mipi_arst_n_i => KEY(0),
      d8m_mipi_clk_o => d8m_mipi_clk_s,
      d8m_mipi_srst_n_o => sync_d8m_mipi_rst_n_s,
      vid_clk_base_i => HDMI_CLOCK_p,
      vid_arst_n_i => KEY(0),
      vid_clk_o => clk_video_s,
      vid_srst_n_o => sync_video_rst_n_s
    );
  
  -- synchronize signals for CPU
  cpu_flags_gen_u : register_clk_resync
    generic map (
      reg_width => 2,
      resync_stages => 2
    ) port map (
      clk_i => clk_sys_s,
      clk_en_i  => TRUE,
      nrst_i => sync_cpu_rst_n_s,
      reg_preset_i(1) => '1',
      reg_i(1) => SW(0),
      reg_o(1) => n_use_rgb2ycbcr_cpu_s,
      reg_preset_i(0) => VSYNC_ACTIVE_POLARITY_1080P,
      reg_i(0) => videosync_a(0).vsync,
      reg_o(0) => cpu_sync_s
    );
  
  -- cast rtl version to hw_info_s signal
  hw_info_s <= to_unsigned_std_logic_vector(VERSION_MAIN,VERSION_MAIN_LENGTH) & to_unsigned_std_logic_vector(VERSION_SUB,VERSION_SUB_LENGTH);
  
  system_u : c5g_housekeeping
    port map (
      clk_clk                        => clk_sys_s,
      rst_reset_n                    => sync_cpu_rst_n_s,
      i2c_master_scl_padoen_export   => cpu_scl_padoen_o,
      i2c_master_scl_pad_i_export    => cpu_scl_pad_i,
      i2c_master_scl_pad_o_export    => cpu_scl_pad_o,
      i2c_master_sda_padoen_o_export => cpu_sda_padoen_o,
      i2c_master_sda_pad_i_export    => cpu_sda_pad_i,
      i2c_master_sda_pad_o_export    => cpu_sda_pad_o,
      i2c_device_select_export       => cpu_i2c_device_select,
      camera_pwdn_n_export           => CAMERA_PWDN_n,
      mipi_reset_n_export            => MIPI_RESET_n,
      interrupts_n_export            => HDMI_TX_INT,
      pll_lock_states_export         => d8m_pll_lock_state_s,
      n_use_rgb2ycbcr_in_export      => n_use_rgb2ycbcr_cpu_s,
      cpu_sync_in_export             => cpu_sync_s,
      hw_info_in_export              => hw_info_s
    );
  
  with cpu_i2c_device_select select cpu_scl_pad_i <= 
    I2C_SCL        when "00",
    CAMERA_I2C_SCL when "01",
    MIPI_I2C_SCL   when "10",
    '1'            when others;
  with cpu_i2c_device_select select cpu_sda_pad_i <= 
    I2C_SDA        when "00",
    CAMERA_I2C_SDA when "01",
    MIPI_I2C_SDA   when "10",
    '1'            when others;
  
  I2C_SCL <= cpu_scl_pad_o when cpu_scl_padoen_o = '0' and  cpu_i2c_device_select = "00" else 'Z';
  I2C_SDA <= cpu_sda_pad_o when cpu_sda_padoen_o = '0' and  cpu_i2c_device_select = "00" else 'Z';
  
  CAMERA_I2C_SCL <= cpu_scl_pad_o when cpu_scl_padoen_o = '0' and  cpu_i2c_device_select = "01" else 'Z';
  CAMERA_I2C_SDA <= cpu_sda_pad_o when cpu_sda_padoen_o = '0' and  cpu_i2c_device_select = "01" else 'Z';
  
  MIPI_I2C_SCL <= cpu_scl_pad_o when cpu_scl_padoen_o = '0' and  cpu_i2c_device_select = "10" else 'Z';
  MIPI_I2C_SDA <= cpu_sda_pad_o when cpu_sda_padoen_o = '0' and  cpu_i2c_device_select = "10" else 'Z';
  
  LEDG(1 downto 0) <= cpu_i2c_device_select;
  
  
  -----------------------
  -- D8M CAMERA MODULE --
  -----------------------
  
  -- connect outputs to D8M module
  MIPI_REFCLK <= clk_d8m_s;
  MIPI_CS_n <= '0';
  
--  LEDR <= MIPI_PIXEL_D;
--  LEDG(7) <= MIPI_PIXEL_HS;
--  LEDG(6) <= MIPI_PIXEL_VS;
--
---- set testing counter for D8M module HS and VS clock counter:
--  d8m_counter_hv : process(d8m_mipi_clk_s) 
--    variable hs_pre_v, vs_pre_v : std_logic := '0';
--  begin
--    if rising_edge(d8m_mipi_clk_s) then
--      if (hs_pre_v = '1' and MIPI_PIXEL_HS = '0') then -- hsync falling
--        d8m_hs_cnt <= 0;
--      else
--        d8m_hs_cnt <= d8m_hs_cnt + 1;
--      end if;
--      if (vs_pre_v = '1' and MIPI_PIXEL_VS = '0') then -- vsync falling
--        d8m_vs_cnt <= 0;
--      else
--        if (hs_pre_v = '1' and MIPI_PIXEL_HS = '0') then -- hsync falling
--          d8m_vs_cnt <= d8m_vs_cnt + 1;
--        end if;
--      end if;
--      hs_pre_v := MIPI_PIXEL_HS;
--      vs_pre_v := MIPI_PIXEL_VS;
--    end if;
--  end process d8m_counter_hv;
  
  
  --------------------
  -- VIDEO PIPELINE --
  --------------------
  
  -- Bayer Pattern Reconstruction
  bayer2rgb_u : bayer2rgb
    port map (
      clk_i => d8m_mipi_clk_s,
      rstn_i => sync_d8m_mipi_rst_n_s,
      hs_i => MIPI_PIXEL_HS,
      vs_i => MIPI_PIXEL_VS,
      camera_pixel_i => MIPI_PIXEL_D,
      hs_o => d8m_rgb_hs_s,
      vs_o => d8m_rgb_vs_s,
      de_o => d8m_rgb_de_s,
      rgb_pixel_o => d8m_rgb_pixel_s
    );
    
  led_test_proc : process (d8m_mipi_clk_s)
    variable rgb_cycle_v : natural range 0 to 2 := 0;
  begin
    if (rising_edge(d8m_mipi_clk_s)) then
      if (rgb_cycle_v = 0) then
        LEDR <= std_logic_vector(d8m_rgb_pixel_s.r);
        rgb_cycle_v := 1;
      elsif (rgb_cycle_v = 1) then
        LEDR <= std_logic_vector(d8m_rgb_pixel_s.g);
        rgb_cycle_v := 2;
      else
        LEDR <= std_logic_vector(d8m_rgb_pixel_s.b);
        rgb_cycle_v := 0;
      end if;
      LEDG(7) <= d8m_rgb_hs_s;
      LEDG(6) <= d8m_rgb_hs_s;
    end if;
  end process led_test_proc;
    
  -- set testing counter for D8M module HS and VS clock counter:
  d8m_counter_hv : process(d8m_mipi_clk_s) 
    variable hs_pre_v, vs_pre_v : std_logic := '0';
  begin
    if rising_edge(d8m_mipi_clk_s) then
      if ((hs_pre_v = '1' and d8m_rgb_hs_s = '0') or      -- hsync falling
          (vs_pre_v = '0' and d8m_rgb_vs_s = '1')) then   -- vsync rising
        d8m_hs_cnt <= 0;
      else
        d8m_hs_cnt <= d8m_hs_cnt + 1;
      end if;
      if (vs_pre_v = '1' and d8m_rgb_vs_s = '0') then -- vsync falling
        d8m_vs_cnt <= 0;
      else
        if (hs_pre_v = '1' and d8m_rgb_hs_s = '0') then -- hsync falling
          d8m_vs_cnt <= d8m_vs_cnt + 1;
        end if;
      end if;
      hs_pre_v := d8m_rgb_hs_s;
      vs_pre_v := d8m_rgb_vs_s;
    end if;
  end process d8m_counter_hv;
  
  
  -- HDMI sync generate
  hdmi_sync_gen_u : sync_gen_1080p
    port map (
      vclk_i => clk_video_s,
      rstn_i => sync_video_rst_n_s,
      xpos_o => xpos_s,
      ypos_o => ypos_s,
      hsync_o => videosync_a(0).hsync,
      vsync_o => videosync_a(0).vsync,
      csync_o => videosync_a(0).csync,
      de_o => videosync_a(0).de
    );
  
  -- test image
  d8m_trigger_sync_gen_u : register_clk_resync
    generic map (
      reg_width => 1,
      resync_stages => 2
    ) port map (
      clk_i => d8m_mipi_clk_s,
      clk_en_i  => TRUE,
      nrst_i => sync_d8m_mipi_rst_n_s,
      reg_preset_i(0) => '1',
      reg_i(0) => KEY(3),
      reg_o(0) => d8m_capture_ntrigger_s
    );
  
  testimg_gen_u : testimg -- generates a delay of four clock cycles at the output
    port map (
      tst_clk_i => d8m_mipi_clk_s,
      tst_nrst_i => sync_d8m_mipi_rst_n_s,
      tst_capture_ntrigger_i => d8m_capture_ntrigger_s,
      tst_hs_i => d8m_rgb_hs_s,
      tst_vs_i => d8m_rgb_vs_s,
      tst_de_i => d8m_rgb_de_s,
      tst_rgb_pixel_i => d8m_rgb_pixel_s,
      vclk_i => clk_video_s,
      rstn_i => sync_video_rst_n_s,
      xpos_i => xpos_s,
      ypos_i => ypos_s,
      videodata_rgb_o => videodata_rgb_s
    );
  
  -- generate YCbCr signal
  g_ASSIGN_VDATA_RGB_TMP_0 : if (rgb_color_depth > camera_pixel_depth) generate
    videodata_rgb_tmp_s.r(rgb_color_depth-1 downto rgb_color_depth-camera_pixel_depth) <= videodata_rgb_s.r;
    videodata_rgb_tmp_s.r(rgb_color_depth-camera_pixel_depth-1 downto 0) <= (others => '0');
    videodata_rgb_tmp_s.g(rgb_color_depth-1 downto rgb_color_depth-camera_pixel_depth) <= videodata_rgb_s.g;
    videodata_rgb_tmp_s.g(rgb_color_depth-camera_pixel_depth-1 downto 0) <= (others => '0');
    videodata_rgb_tmp_s.b(rgb_color_depth-1 downto rgb_color_depth-camera_pixel_depth) <= videodata_rgb_s.b;
    videodata_rgb_tmp_s.b(rgb_color_depth-camera_pixel_depth-1 downto 0) <= (others => '0');
  end generate g_ASSIGN_VDATA_RGB_TMP_0;
  
  g_ASSIGN_VDATA_RGB_TMP_1 : if (rgb_color_depth <= camera_pixel_depth) generate
    videodata_rgb_tmp_s.r <= videodata_rgb_s.r(camera_pixel_depth-1 downto camera_pixel_depth-rgb_color_depth);
    videodata_rgb_tmp_s.g <= videodata_rgb_s.g(camera_pixel_depth-1 downto camera_pixel_depth-rgb_color_depth);
    videodata_rgb_tmp_s.b <= videodata_rgb_s.b(camera_pixel_depth-1 downto camera_pixel_depth-rgb_color_depth);
  end generate g_ASSIGN_VDATA_RGB_TMP_1;
  
  ycbcr_top_u : ycbcr_design -- color transformation RGB to YCbCr
    port map (
      nrst => sync_video_rst_n_s,
      clk => clk_video_s,
      pixel_in => videodata_rgb_tmp_s,
      pixel_out => videodata_ycbcr_s
    );
  
  -- synchronize signals for CPU
  video_tx_flags_gen_u : register_clk_resync
    generic map (
      reg_width => 1,
      resync_stages => 1
    ) port map (
      clk_i => clk_video_s,
      clk_en_i  => TRUE,
      nrst_i => sync_video_rst_n_s,
      reg_preset_i(0) => '0',
      reg_i(0) => SW(0),
      reg_o(0) => n_use_rgb2ycbcr_fpga_s
    );
  
  -- connect hdmi output signals
  HDMI_TX_CLK <= clk_video_s;
  
  -- assume always that internal processing width is higher than what we give to the video interface
  videosignal_rgb_s.ch1 <= std_logic_vector(videodata_rgb_s.r(camera_pixel_depth-1 downto camera_pixel_depth-video_color_depth));
  videosignal_rgb_s.ch2 <= std_logic_vector(videodata_rgb_s.g(camera_pixel_depth-1 downto camera_pixel_depth-video_color_depth));
  videosignal_rgb_s.ch3 <= std_logic_vector(videodata_rgb_s.b(camera_pixel_depth-1 downto camera_pixel_depth-video_color_depth));
  
  videosignal_ycbcr_s.ch1 <= std_logic_vector(videodata_ycbcr_s.cr(ycbcr_color_depth-1 downto ycbcr_color_depth-video_color_depth));
  videosignal_ycbcr_s.ch2 <= std_logic_vector(videodata_ycbcr_s.y(ycbcr_color_depth-1 downto ycbcr_color_depth-video_color_depth));
  videosignal_ycbcr_s.ch3 <= std_logic_vector(videodata_ycbcr_s.cb(ycbcr_color_depth-1 downto ycbcr_color_depth-video_color_depth));
  
  process (clk_video_s) begin
    if rising_edge(clk_video_s) then
      if (n_use_rgb2ycbcr_fpga_s = '0') then
        HDMI_TX_D <= videosignal_ycbcr_s.ch1 & videosignal_ycbcr_s.ch2 & videosignal_ycbcr_s.ch3;
        HDMI_TX_DE <= videosync_a(VIDEO_PIPELINE_LENGTH+VIDEO_RGB2YCBCR_PIPELINE_LENGTH).de;
        HDMI_TX_HS <= videosync_a(VIDEO_PIPELINE_LENGTH+VIDEO_RGB2YCBCR_PIPELINE_LENGTH).hsync;
        HDMI_TX_VS <= videosync_a(VIDEO_PIPELINE_LENGTH+VIDEO_RGB2YCBCR_PIPELINE_LENGTH).vsync;
      else
        HDMI_TX_D <= videosignal_rgb_s.ch1 & videosignal_rgb_s.ch2 & videosignal_rgb_s.ch3;
        HDMI_TX_DE <= videosync_a(VIDEO_PIPELINE_LENGTH).de;
        HDMI_TX_HS <= videosync_a(VIDEO_PIPELINE_LENGTH).hsync;
        HDMI_TX_VS <= videosync_a(VIDEO_PIPELINE_LENGTH).vsync;
      end if;
      
      for idx in (VIDEO_PIPELINE_LENGTH+VIDEO_RGB2YCBCR_PIPELINE_LENGTH) downto 1 loop
        videosync_a(idx) <= videosync_a(idx-1);
      end loop;
    end if;
  end process;

end behavioral;
