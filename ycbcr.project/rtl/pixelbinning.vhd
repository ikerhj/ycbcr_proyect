library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.camera2hdmi_pack.all;
use work.d8m_timings.all;
use work.macros.all;


entity pixelbinning is

  generic (
    h_active_in : natural := D8M_H_ACTIVE_1080P;
    h_active_out : natural := 320;
    h_bin_factor : natural range 1 to 4 := 4;
    v_active_in : natural := D8M_V_ACTIVE_1080P;
    v_active_out : natural := 240;
    v_bin_factor : natural range 1 to 4 := 4
  );
  
  port (
    clk_i : in std_logic;
    nrst_i : in std_logic;
    
    hs_i : in std_logic;
    vs_i : in std_logic;
    de_i : in boolean;
    rgb_pixel_i : in camera_rgb_pixel_t;
    
    bypass_pixel_binning : in boolean;
    
    xpos_o : out natural range 0 to h_active_out-1 := 0;
    ypos_o : out natural range 0 to v_active_out-1 := 0;
    pixel_valid_o : out boolean := FALSE;
    rgb_pixel_o : out camera_rgb_pixel_t := (others => to_unsigned(0,camera_pixel_depth))
  );
  
end entity pixelbinning;

architecture behavioral of pixelbinning is

  -- calculate some constants
  constant h_start : natural := (D8M_H_ACTIVE_1080P - h_bin_factor*h_active_out)/2;
  constant h_stop : natural := (D8M_H_ACTIVE_1080P + h_bin_factor*h_active_out)/2;
  constant v_start : natural := (D8M_V_ACTIVE_1080P - v_bin_factor*v_active_out)/2;
  constant v_stop : natural := (D8M_V_ACTIVE_1080P + v_bin_factor*v_active_out)/2;
  
  constant h_bin_pixel_depth : natural := 2**(log2_ceil(h_bin_factor-1)-1)+camera_pixel_depth;
  constant v_bin_pixel_depth : natural := 2**(log2_ceil(v_bin_factor-1)-1)+camera_pixel_depth;
  constant hv_bin_pixel_depth : natural := 2**(log2_ceil(h_bin_factor-1)-1)+2**(log2_ceil(v_bin_factor-1)-1)+camera_pixel_depth;
  
  constant h_pixel_zero_extension : unsigned(h_bin_pixel_depth-camera_pixel_depth-1 downto 0) := (others => '0');
  constant v_pixel_zero_extension : unsigned(v_bin_pixel_depth-camera_pixel_depth-1 downto 0) := (others => '0');
  constant hv_pixel_zero_extension : unsigned(hv_bin_pixel_depth-camera_pixel_depth-1 downto 0) := (others => '0');
  
  -- types declarations
  type h_binned_rgb_pixel_t is
    record
      r : unsigned(h_bin_pixel_depth-1 downto 0);
      g : unsigned(h_bin_pixel_depth-1 downto 0);
      b : unsigned(h_bin_pixel_depth-1 downto 0);
    end record;
  type hv_binned_rgb_pixel_t is
    record
      r : unsigned(hv_bin_pixel_depth-1 downto 0);
      g : unsigned(hv_bin_pixel_depth-1 downto 0);
      b : unsigned(hv_bin_pixel_depth-1 downto 0);
    end record;
  
  type linebuffer_1ch_t is array (0 to 2**log2_ceil(h_active_out)-1) of unsigned(h_bin_pixel_depth-1 downto 0);
  
  -- signal declaration
  signal d8m_hs_cnt_s : natural range 0 to 2**D8M_H_CNT_WIDTH-1 := 0;
  signal d8m_vs_cnt_s : natural range 0 to 2**D8M_V_CNT_WIDTH-1 := 0;
  signal d8m_de_L_s : boolean := FALSE;
  signal rgb_pixel_L_s : camera_rgb_pixel_t := (others => to_unsigned(0,camera_pixel_depth));
  
  signal wren_buffer_s, rden_buffer_s : boolean := FALSE;
  signal actaddr_buffer_s : natural range 0 to h_active_out-1 := 0;
  signal wrline_buffer_s : natural range 0 to v_bin_factor-2 := 0;
  signal output_line_s : natural range 0 to v_active_out-1 := 0;
  signal tmp_h_pixel_bin_s : h_binned_rgb_pixel_t := (others => (others => '0'));
  signal tmp_hv_pixel_bin_s : hv_binned_rgb_pixel_t := (others => (others => '0'));
  
  attribute ramstyle : string;
  signal pixelbuffer_l0_r_s : linebuffer_1ch_t := (others => (others => '0'));
    attribute ramstyle of pixelbuffer_l0_r_s : signal is "M10K";
  signal pixelbuffer_l0_g_s : linebuffer_1ch_t := (others => (others => '0'));
    attribute ramstyle of pixelbuffer_l0_g_s : signal is "M10K";
  signal pixelbuffer_l0_b_s : linebuffer_1ch_t := (others => (others => '0'));
    attribute ramstyle of pixelbuffer_l0_b_s : signal is "M10K";
  signal pixelbuffer_l1_r_s : linebuffer_1ch_t := (others => (others => '0'));
    attribute ramstyle of pixelbuffer_l1_r_s : signal is "M10K";
  signal pixelbuffer_l1_g_s : linebuffer_1ch_t := (others => (others => '0'));
    attribute ramstyle of pixelbuffer_l1_g_s : signal is "M10K";
  signal pixelbuffer_l1_b_s : linebuffer_1ch_t := (others => (others => '0'));
    attribute ramstyle of pixelbuffer_l1_b_s : signal is "M10K";
  signal pixelbuffer_l2_r_s : linebuffer_1ch_t := (others => (others => '0'));
    attribute ramstyle of pixelbuffer_l2_r_s : signal is "M10K";
  signal pixelbuffer_l2_g_s : linebuffer_1ch_t := (others => (others => '0'));
    attribute ramstyle of pixelbuffer_l2_g_s : signal is "M10K";
  signal pixelbuffer_l2_b_s : linebuffer_1ch_t := (others => (others => '0'));
    attribute ramstyle of pixelbuffer_l2_b_s : signal is "M10K";

begin

  -- generate input counter and delay inputs to keep everything aligned
  process(clk_i, nrst_i) 
    variable hs_pre_v, vs_pre_v : std_logic := '0';
  begin
    if (nrst_i = '0') then
      d8m_hs_cnt_s <= 0;
      d8m_vs_cnt_s <= 0;
      d8m_de_L_s <= FALSE;
      rgb_pixel_L_s <= (others => to_unsigned(0,camera_pixel_depth));
      hs_pre_v := D8M_HSYNC_ACTIVE_POLARITY_1080P;
      vs_pre_v := D8M_VSYNC_ACTIVE_POLARITY_1080P;
    elsif rising_edge(clk_i) then
      if ((hs_pre_v = D8M_HSYNC_ACTIVE_POLARITY_1080P and hs_i = not(D8M_HSYNC_ACTIVE_POLARITY_1080P)) or     -- hsync becomes inactive, or
          (vs_pre_v = D8M_VSYNC_ACTIVE_POLARITY_1080P and vs_i = not(D8M_VSYNC_ACTIVE_POLARITY_1080P))) then  -- vsync active ends
        d8m_hs_cnt_s <= 0;
      else
        d8m_hs_cnt_s <= d8m_hs_cnt_s + 1;
      end if;
      if (vs_pre_v = not(D8M_VSYNC_ACTIVE_POLARITY_1080P) and vs_i = D8M_VSYNC_ACTIVE_POLARITY_1080P) then    -- vsync becomes active
        d8m_vs_cnt_s <= 0;
      else
        if (hs_pre_v = not(D8M_HSYNC_ACTIVE_POLARITY_1080P) and hs_i = D8M_HSYNC_ACTIVE_POLARITY_1080P) then  -- hsync becomes active
          d8m_vs_cnt_s <= d8m_vs_cnt_s + 1;
        end if;
      end if;
      hs_pre_v := hs_i;
      vs_pre_v := vs_i;
      d8m_de_L_s <= de_i;
      rgb_pixel_L_s <= rgb_pixel_i;
    end if;
  end process;
  
  process (clk_i,nrst_i) is
    variable x_inbin_cnt_v : natural range 0 to h_bin_factor-1 := 0;
    variable x_binnum_cnt_v : natural range 0 to h_active_out-1 := 0;
    variable x_capture_valid_v : boolean := FALSE;
    
    variable y_inbin_cnt_v : natural range 0 to v_bin_factor-1 := 0;
    variable y_binnum_cnt_v : natural range 0 to v_active_out-1 := 0;
    variable y_capture_valid_v : boolean := FALSE;
  begin
    if (nrst_i = '0') then
      wren_buffer_s <= FALSE;
      rden_buffer_s <= FALSE;
      wrline_buffer_s <= 0;
      actaddr_buffer_s <= 0;
      output_line_s <= 0;
      
      x_inbin_cnt_v := 0;
      x_binnum_cnt_v := 0;
      x_capture_valid_v := FALSE;
      y_inbin_cnt_v := 0;
      y_binnum_cnt_v := 0;
      y_capture_valid_v := FALSE;
    elsif (rising_edge(clk_i)) then
      -- pixel calculation and register of buffer inputs
      if ((d8m_hs_cnt_s >= h_start) and (d8m_hs_cnt_s < h_stop) and (d8m_vs_cnt_s >= v_start) and (d8m_vs_cnt_s < v_stop)) then -- binning area
        if (bypass_pixel_binning) then
          if (x_inbin_cnt_v = 2) then
            tmp_h_pixel_bin_s.r <= (rgb_pixel_L_s.r & h_pixel_zero_extension);
            tmp_h_pixel_bin_s.g <= (rgb_pixel_L_s.g & h_pixel_zero_extension);
            tmp_h_pixel_bin_s.b <= (rgb_pixel_L_s.b & h_pixel_zero_extension);
          end if;
        else
          if (x_inbin_cnt_v = 0) then
            tmp_h_pixel_bin_s.r <= (h_pixel_zero_extension & rgb_pixel_L_s.r);
            tmp_h_pixel_bin_s.g <= (h_pixel_zero_extension & rgb_pixel_L_s.g);
            tmp_h_pixel_bin_s.b <= (h_pixel_zero_extension & rgb_pixel_L_s.b);
          else
            tmp_h_pixel_bin_s.r <= tmp_h_pixel_bin_s.r + (h_pixel_zero_extension & rgb_pixel_L_s.r);
            tmp_h_pixel_bin_s.g <= tmp_h_pixel_bin_s.g + (h_pixel_zero_extension & rgb_pixel_L_s.g);
            tmp_h_pixel_bin_s.b <= tmp_h_pixel_bin_s.b + (h_pixel_zero_extension & rgb_pixel_L_s.b);
          end if;
        end if;
        if (x_capture_valid_v) then
          actaddr_buffer_s <= x_binnum_cnt_v;
          wrline_buffer_s <= y_inbin_cnt_v;
          output_line_s <= y_binnum_cnt_v;
          if (y_capture_valid_v) then
            wren_buffer_s <= FALSE;
            rden_buffer_s <= TRUE;
          else
            wren_buffer_s <= TRUE;
            rden_buffer_s <= FALSE;
          end if;
        else
          wren_buffer_s <= FALSE;
          rden_buffer_s <= FALSE;
        end if;
      else
        wren_buffer_s <= FALSE;
        rden_buffer_s <= FALSE;
      end if;
      
      -- horizontal counter management
      if (d8m_hs_cnt_s >= h_start and d8m_hs_cnt_s < h_stop) then
        if (x_capture_valid_v) then -- capture was valid in previous cycle, so we can increase x_binnum_cnt_v now for the next round
          x_binnum_cnt_v := x_binnum_cnt_v + 1;
        end if;
        if (x_inbin_cnt_v = h_bin_factor-1) then
          x_inbin_cnt_v := 0;
        else
          x_inbin_cnt_v := x_inbin_cnt_v + 1;
        end if;
        x_capture_valid_v := (x_inbin_cnt_v = h_bin_factor-1);
      else
        x_inbin_cnt_v := 0;
        x_binnum_cnt_v := 0;
        x_capture_valid_v := FALSE;
      end if;
      -- vertical counter management
      if (d8m_hs_cnt_s = h_stop-1) then
        if (d8m_vs_cnt_s >= v_start and d8m_vs_cnt_s < v_stop) then
          if (y_capture_valid_v) then -- capture was valid in previous line, so we can increase y_binnum_cnt_v now for the next round
            y_binnum_cnt_v := y_binnum_cnt_v + 1;
          end if;
          if (y_inbin_cnt_v = v_bin_factor-1) then
            y_inbin_cnt_v := 0;
          else
            y_inbin_cnt_v := y_inbin_cnt_v + 1;
          end if;
          y_capture_valid_v := (y_inbin_cnt_v = v_bin_factor-1);
        else
          y_inbin_cnt_v := 0;
          y_binnum_cnt_v := 0;
          y_capture_valid_v := FALSE;
        end if;
      end if;
--      end if;
    end if;
  end process;
  
  -- buffer management
  process (clk_i,nrst_i) is
    variable tmp_h_pixel_l0_v : h_binned_rgb_pixel_t := (others => (others => '0'));
    variable tmp_h_pixel_l1_v : h_binned_rgb_pixel_t := (others => (others => '0'));
    variable tmp_h_pixel_l2_v : h_binned_rgb_pixel_t := (others => (others => '0'));
    variable tmp_h_pixel_l3_v : h_binned_rgb_pixel_t := (others => (others => '0'));
    variable xpos_pre_v : natural range 0 to h_active_out-1 := 0;
    variable ypos_pre_v : natural range 0 to v_active_out-1 := 0;
    variable pixel_valid_pre_v : boolean := FALSE;
  begin
    if (nrst_i = '0') then
      tmp_h_pixel_l0_v := (others => (others => '0'));
      tmp_h_pixel_l1_v := (others => (others => '0'));
      tmp_h_pixel_l2_v := (others => (others => '0'));
      tmp_h_pixel_l3_v := (others => (others => '0'));
      xpos_pre_v := 0;
      ypos_pre_v := 0;
      pixel_valid_pre_v := FALSE;
      xpos_o <= 0;
      ypos_o <= 0;
      pixel_valid_o <= FALSE;
      tmp_hv_pixel_bin_s <= (others => (others => '0'));
    elsif (rising_edge(clk_i)) then
      if (pixel_valid_pre_v) then
        if (bypass_pixel_binning) then
          tmp_hv_pixel_bin_s.r <= (tmp_h_pixel_l2_v.r & v_pixel_zero_extension);
          tmp_hv_pixel_bin_s.g <= (tmp_h_pixel_l2_v.g & v_pixel_zero_extension);
          tmp_hv_pixel_bin_s.b <= (tmp_h_pixel_l2_v.b & v_pixel_zero_extension);
        else
          tmp_hv_pixel_bin_s.r <=    (v_pixel_zero_extension & tmp_h_pixel_l0_v.r)
                                   + (v_pixel_zero_extension & tmp_h_pixel_l1_v.r)
                                   + (v_pixel_zero_extension & tmp_h_pixel_l2_v.r)
                                   + (v_pixel_zero_extension & tmp_h_pixel_l3_v.r);
          tmp_hv_pixel_bin_s.g <=    (v_pixel_zero_extension & tmp_h_pixel_l0_v.g)
                                   + (v_pixel_zero_extension & tmp_h_pixel_l1_v.g)
                                   + (v_pixel_zero_extension & tmp_h_pixel_l2_v.g)
                                   + (v_pixel_zero_extension & tmp_h_pixel_l3_v.g);
          tmp_hv_pixel_bin_s.b <=    (v_pixel_zero_extension & tmp_h_pixel_l0_v.b)
                                   + (v_pixel_zero_extension & tmp_h_pixel_l1_v.b)
                                   + (v_pixel_zero_extension & tmp_h_pixel_l2_v.b)
                                   + (v_pixel_zero_extension & tmp_h_pixel_l3_v.b);
        end if;
        xpos_o <= xpos_pre_v;
        ypos_o <= ypos_pre_v;
      end if;
      pixel_valid_o <= pixel_valid_pre_v;
      
      if (rden_buffer_s) then
        tmp_h_pixel_l0_v.r := pixelbuffer_l0_r_s(actaddr_buffer_s);
        tmp_h_pixel_l0_v.g := pixelbuffer_l0_g_s(actaddr_buffer_s);
        tmp_h_pixel_l0_v.b := pixelbuffer_l0_b_s(actaddr_buffer_s);
        tmp_h_pixel_l1_v.r := pixelbuffer_l1_r_s(actaddr_buffer_s);
        tmp_h_pixel_l1_v.g := pixelbuffer_l1_g_s(actaddr_buffer_s);
        tmp_h_pixel_l1_v.b := pixelbuffer_l1_b_s(actaddr_buffer_s);
        tmp_h_pixel_l2_v.r := pixelbuffer_l2_r_s(actaddr_buffer_s);
        tmp_h_pixel_l2_v.g := pixelbuffer_l2_g_s(actaddr_buffer_s);
        tmp_h_pixel_l2_v.b := pixelbuffer_l2_b_s(actaddr_buffer_s);
        tmp_h_pixel_l3_v := tmp_h_pixel_bin_s;
        xpos_pre_v := actaddr_buffer_s;
        ypos_pre_v := output_line_s;
        pixel_valid_pre_v := TRUE;
      else
        pixel_valid_pre_v := FALSE;
      end if;
      if (wren_buffer_s) then
        case (wrline_buffer_s) is
          when 0 =>
            pixelbuffer_l0_r_s(actaddr_buffer_s) <= tmp_h_pixel_bin_s.r;
            pixelbuffer_l0_g_s(actaddr_buffer_s) <= tmp_h_pixel_bin_s.g;
            pixelbuffer_l0_b_s(actaddr_buffer_s) <= tmp_h_pixel_bin_s.b;
          when 1 =>
            pixelbuffer_l1_r_s(actaddr_buffer_s) <= tmp_h_pixel_bin_s.r;
            pixelbuffer_l1_g_s(actaddr_buffer_s) <= tmp_h_pixel_bin_s.g;
            pixelbuffer_l1_b_s(actaddr_buffer_s) <= tmp_h_pixel_bin_s.b;
          when others =>
            pixelbuffer_l2_r_s(actaddr_buffer_s) <= tmp_h_pixel_bin_s.r;
            pixelbuffer_l2_g_s(actaddr_buffer_s) <= tmp_h_pixel_bin_s.g;
            pixelbuffer_l2_b_s(actaddr_buffer_s) <= tmp_h_pixel_bin_s.b;
        end case;
      end if;
    end if;
  end process;

  -- get outputs
  rgb_pixel_o.r <= tmp_hv_pixel_bin_s.r(hv_bin_pixel_depth-1 downto hv_bin_pixel_depth-camera_pixel_depth);
  rgb_pixel_o.g <= tmp_hv_pixel_bin_s.g(hv_bin_pixel_depth-1 downto hv_bin_pixel_depth-camera_pixel_depth);
  rgb_pixel_o.b <= tmp_hv_pixel_bin_s.b(hv_bin_pixel_depth-1 downto hv_bin_pixel_depth-camera_pixel_depth);

end behavioral;
