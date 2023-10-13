library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.camera2hdmi_pack.all;
use work.macros.all;
use work.d8m_timings.all;


entity bayer2rgb is

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

end bayer2rgb;


architecture behavioral of bayer2rgb is

  -- signals
  signal hs_L_s : std_logic := D8M_HSYNC_ACTIVE_POLARITY_1080P;
  signal vs_L_s : std_logic := D8M_VSYNC_ACTIVE_POLARITY_1080P;
  signal negedge_hs_s : boolean;   -- should be active if horizontal area goes into blanking area
  
  signal hcnt_s : natural range 0 to D8M_H_ACTIVE_1080P-1 := 0;
  signal vcnt_s : natural range 0 to D8M_V_ACTIVE_1080P := 0;
  
  signal line_id_s : std_logic := '0';    -- lind_id = 0 -> BGBGBGB..., line_id = 1 -> GRGRGRGR...
  signal color_id_s : std_logic := '0';   -- color_id = 0 -> B/R, color_id = 1 -> G
  
  
  -- define the arrays to store 25 pixels: pixels and dummies
  type calc_matrix_row_t is array (4 downto 0) of std_logic_vector(9 downto 0);
  type bayer_matrix_t is array (0 to 4) of calc_matrix_row_t;
  --  the formation of the whole matrix:
  --       4        3         2         1         0
  --  0: dummy 1, dummy  5, pixel  1, dummy  7, dummy  9
  --  1: dummy 2, pixel  2, pixel  3, pixel  4, dummy 10
  --  2: pixel 5, pixel  6, pixel  7, pixel  8, pixel  9
  --  3: dummy 3, pixel 10, pixel 11, pixel 12, dummy 11
  --  4: dummy 4, dummy  6, pixel 13, dummy  8, dummy 12
  
  signal calc_matrix_s : bayer_matrix_t := (others => (others => (others => '0')));
    -- just for handling the pixels according to the scheme shown above
    signal                         pixel_01_s                         : unsigned(camera_pixel_depth+1 downto 0);
    signal             pixel_02_s, pixel_03_s, pixel_04_s             : unsigned(camera_pixel_depth+1 downto 0);
    signal pixel_05_s, pixel_06_s, pixel_07_s, pixel_08_s, pixel_09_s : unsigned(camera_pixel_depth+1 downto 0);
    signal             pixel_10_s, pixel_11_s, pixel_12_s             : unsigned(camera_pixel_depth+1 downto 0);
    signal                         pixel_13_s                         : unsigned(camera_pixel_depth+1 downto 0);
  
    function extend_pixel_unsigned(
        pixel_i : std_logic_vector(camera_pixel_depth-1 downto 0)
      ) return unsigned is
      variable retval : std_logic_vector(camera_pixel_depth+1 downto 0);
    begin
      retval := "00" & pixel_i;
      return unsigned(retval);
    end function;
    
    function pixel_diff_func(
        pixel_a : unsigned(camera_pixel_depth+1 downto 0) := (others => '0');
        pixel_b : unsigned(camera_pixel_depth+1 downto 0) := (others => '0')
      ) return unsigned is
      variable retval : unsigned(camera_pixel_depth+1 downto 0);
    begin
      if (pixel_a < pixel_b) then
        retval := pixel_b - pixel_a;
      else
        retval := pixel_a - pixel_b;
      end if;
      return retval;
    end function;
  
  
  -- define the arrays which store lines:
  type linebuffer_t is array (0 to 2**log2_ceil(D8M_H_ACTIVE_1080P)-1) of std_logic_vector(camera_pixel_depth-1 downto 0);
  
  attribute ramstyle : string;
  signal pixelbuffer_l0_s : linebuffer_t := (others => (others => '0'));
    attribute ramstyle of pixelbuffer_l0_s : signal is "M10K";
  signal pixelbuffer_l1_s : linebuffer_t := (others => (others => '0'));
    attribute ramstyle of pixelbuffer_l1_s : signal is "M10K";
  signal pixelbuffer_l2_s : linebuffer_t := (others => (others => '0'));
    attribute ramstyle of pixelbuffer_l2_s : signal is "M10K";
  signal pixelbuffer_l3_s : linebuffer_t := (others => (others => '0'));
    attribute ramstyle of pixelbuffer_l3_s : signal is "M10K";
  signal pixelbuffer_l4_s : linebuffer_t := (others => (others => '0'));
    attribute ramstyle of pixelbuffer_l4_s : signal is "M10K";
  
begin

  negedge_hs_s <= (hs_L_s = not(D8M_HSYNC_ACTIVE_POLARITY_1080P)) and (hs_i = D8M_HSYNC_ACTIVE_POLARITY_1080P); -- detects if horizontal area goes into blanking area

  process (clk_i, rstn_i)
    variable hcnt_v : natural range 0 to D8M_H_ACTIVE_1080P := 0;
    variable vcnt_v : natural range 0 to D8M_V_ACTIVE_1080P := 0;
    variable vcnt_mod_5_L_v, vcnt_mod_5_v : natural range 0 to 4 := 0;
  begin
    if (rstn_i = '0') then
      hcnt_v := 0;
      vcnt_v := 0;
      vcnt_mod_5_v := 0;
      
      hcnt_s <= 0;
      vcnt_s <= 0;
      hs_L_s <= D8M_HSYNC_ACTIVE_POLARITY_1080P;
      vs_L_s <= D8M_VSYNC_ACTIVE_POLARITY_1080P;
    elsif (rising_edge(clk_i)) then
      
      if (hs_i = not(D8M_HSYNC_ACTIVE_POLARITY_1080P)) then -- active pixel area
        -- shift pixels ...
          calc_matrix_s(0)(4 downto 1) <= calc_matrix_s(0)(3 downto 0);
          calc_matrix_s(1)(4 downto 1) <= calc_matrix_s(1)(3 downto 0);
          calc_matrix_s(2)(4 downto 1) <= calc_matrix_s(2)(3 downto 0);
          calc_matrix_s(3)(4 downto 1) <= calc_matrix_s(3)(3 downto 0);
          calc_matrix_s(4)(4 downto 1) <= calc_matrix_s(4)(3 downto 0);
        -- and capture new one
        case (vcnt_mod_5_v) is
          when 0 => -- line 0 is new, so top calculation row is read from line 1
            pixelbuffer_l0_s(hcnt_s) <= camera_pixel_i;
            calc_matrix_s(0)(0) <= pixelbuffer_l1_s(hcnt_v);
            calc_matrix_s(1)(0) <= pixelbuffer_l2_s(hcnt_v);
            calc_matrix_s(2)(0) <= pixelbuffer_l3_s(hcnt_v);
            calc_matrix_s(3)(0) <= pixelbuffer_l4_s(hcnt_v);
            calc_matrix_s(4)(0) <= camera_pixel_i;
          when 1 => -- line 1 is new, so top calculation row is read from line 2
            pixelbuffer_l1_s(hcnt_s) <= camera_pixel_i;
            calc_matrix_s(0)(0) <= pixelbuffer_l2_s(hcnt_v);
            calc_matrix_s(1)(0) <= pixelbuffer_l3_s(hcnt_v);
            calc_matrix_s(2)(0) <= pixelbuffer_l4_s(hcnt_v);
            calc_matrix_s(3)(0) <= pixelbuffer_l0_s(hcnt_v);
            calc_matrix_s(4)(0) <= camera_pixel_i;
          when 2 => -- line 2 is new, so top calculation row is read from line 3
            pixelbuffer_l2_s(hcnt_s) <= camera_pixel_i;
            calc_matrix_s(0)(0) <= pixelbuffer_l3_s(hcnt_v);
            calc_matrix_s(1)(0) <= pixelbuffer_l4_s(hcnt_v);
            calc_matrix_s(2)(0) <= pixelbuffer_l0_s(hcnt_v);
            calc_matrix_s(3)(0) <= pixelbuffer_l1_s(hcnt_v);
            calc_matrix_s(4)(0) <= camera_pixel_i;
          when 3 => -- line 3 is new, so top calculation row is read from line 4
            pixelbuffer_l3_s(hcnt_s) <= camera_pixel_i;
            calc_matrix_s(0)(0) <= pixelbuffer_l4_s(hcnt_v);
            calc_matrix_s(1)(0) <= pixelbuffer_l0_s(hcnt_v);
            calc_matrix_s(2)(0) <= pixelbuffer_l1_s(hcnt_v);
            calc_matrix_s(3)(0) <= pixelbuffer_l2_s(hcnt_v);
            calc_matrix_s(4)(0) <= camera_pixel_i;
          when 4 => -- line 4 is new, so top calculation row is read from line 0
            pixelbuffer_l4_s(hcnt_s) <= camera_pixel_i;
            calc_matrix_s(0)(0) <= pixelbuffer_l0_s(hcnt_v);
            calc_matrix_s(1)(0) <= pixelbuffer_l1_s(hcnt_v);
            calc_matrix_s(2)(0) <= pixelbuffer_l2_s(hcnt_v);
            calc_matrix_s(3)(0) <= pixelbuffer_l3_s(hcnt_v);
            calc_matrix_s(4)(0) <= camera_pixel_i;
          when others => -- should not happen
            calc_matrix_s <= (others => (others => (others => '0')));
        end case;
      end if;
      
      vcnt_s <= vcnt_v;
      hcnt_s <= hcnt_v;
      if (vs_i = D8M_VSYNC_ACTIVE_POLARITY_1080P) then  -- blanking area
        vcnt_v := 0;
        vcnt_mod_5_v := 0;
        line_id_s <= '0';
      else  -- vertical active area
        if (negedge_hs_s) then -- going into horizontal blanking
          vcnt_v := vcnt_v + 1;
          if (vcnt_mod_5_v = 4) then
            vcnt_mod_5_v := 0;
          else
            vcnt_mod_5_v := vcnt_mod_5_v + 1;
          end if;
          line_id_s <= not(line_id_s);
        end if;
      end if;
    
      if (hs_i = D8M_HSYNC_ACTIVE_POLARITY_1080P) then -- blanking area
        hcnt_v := 0;
        color_id_s <= line_id_s;
      else
        hcnt_v := hcnt_v + 1;
        color_id_s <= not(color_id_s);
      end if;
      
      hs_L_s <= hs_i;
      vs_L_s <= vs_i;
    end if;
  end process;
  
  
  -- assign pixels for calculation
  -- gradient
  pixel_01_s <= extend_pixel_unsigned(calc_matrix_s(0)(2));
  pixel_13_s <= extend_pixel_unsigned(calc_matrix_s(4)(2));
  pixel_05_s <= extend_pixel_unsigned(calc_matrix_s(2)(4));
  pixel_09_s <= extend_pixel_unsigned(calc_matrix_s(2)(0));
  
  -- eval core
  pixel_02_s <= extend_pixel_unsigned(calc_matrix_s(1)(3));
  pixel_03_s <= extend_pixel_unsigned(calc_matrix_s(1)(2));
  pixel_04_s <= extend_pixel_unsigned(calc_matrix_s(1)(1));
  pixel_06_s <= extend_pixel_unsigned(calc_matrix_s(2)(3));
  pixel_07_s <= extend_pixel_unsigned(calc_matrix_s(2)(2));
  pixel_08_s <= extend_pixel_unsigned(calc_matrix_s(2)(1));
  pixel_10_s <= extend_pixel_unsigned(calc_matrix_s(3)(3));
  pixel_11_s <= extend_pixel_unsigned(calc_matrix_s(3)(2));
  pixel_12_s <= extend_pixel_unsigned(calc_matrix_s(3)(1));
  
  process (clk_i, rstn_i)
    variable is_vsync_extension_v : boolean := FALSE;
    variable hcnt_local_v : natural range 0 to D8M_H_SYNCLEN_1080P+D8M_H_ACTIVE_1080P-1 := 0;
    variable vsync_delay_cnt_v : natural range 0 to 3 := 0;
    variable hsync_delay_cnt_v : natural range 0 to 3 := 0;
    
    variable pixel_pattern_v : bit_vector(1 downto 0) := "00";
    variable pixel_diff_ud_v, pixel_diff_lr_v : unsigned(camera_pixel_depth+1 downto 0) := (others => '0');
  begin
    if (rstn_i = '0') then
      is_vsync_extension_v := FALSE;
      hcnt_local_v := 0;
      vsync_delay_cnt_v := 0;
      hsync_delay_cnt_v := 0;
      
      pixel_pattern_v := "00";
      pixel_diff_ud_v := (others => '0');
      pixel_diff_lr_v := (others => '0');
      
      hs_o <= D8M_HSYNC_ACTIVE_POLARITY_1080P;
      vs_o <= D8M_VSYNC_ACTIVE_POLARITY_1080P;
      de_o <= FALSE;
      rgb_pixel_o.r <= (others => '0');
      rgb_pixel_o.g <= (others => '0');
      rgb_pixel_o.b <= (others => '0');
    elsif (rising_edge(clk_i)) then
      -- create sync signals for output
      if (is_vsync_extension_v) then
        if (vsync_delay_cnt_v = 3) then
          is_vsync_extension_v := FALSE;
          de_o <= FALSE;
          vs_o <= D8M_VSYNC_ACTIVE_POLARITY_1080P;
          hs_o <= D8M_HSYNC_ACTIVE_POLARITY_1080P;
        else
          de_o <= not((hcnt_local_v < D8M_H_SYNCLEN_1080P) xor to_boolean(D8M_HSYNC_ACTIVE_POLARITY_1080P));
          vs_o <= not(D8M_VSYNC_ACTIVE_POLARITY_1080P);
          hs_o <= not(to_std_logic(hcnt_local_v < D8M_H_SYNCLEN_1080P) xor D8M_HSYNC_ACTIVE_POLARITY_1080P);
        end if;
        if (hcnt_local_v = D8M_H_SYNCLEN_1080P+D8M_H_ACTIVE_1080P-1) then
          hcnt_local_v := 0;
          vsync_delay_cnt_v := vsync_delay_cnt_v + 1;
        else
          hcnt_local_v := hcnt_local_v + 1;
        end if;
        hsync_delay_cnt_v := 2;
      else
        if (vcnt_s = D8M_V_ACTIVE_1080P) then -- last line done (vcnt_s is one clock cycle ahead of vs_L_s, so we have D8M_V_ACTIVE_1080P for exactly one clock cycle)
          is_vsync_extension_v := TRUE;
          hcnt_local_v := D8M_H_SYNCLEN_1080P+D8M_H_ACTIVE_1080P-1;
        end if;
        if (vcnt_s < 2) then
          vs_o <= D8M_VSYNC_ACTIVE_POLARITY_1080P;
          vsync_delay_cnt_v := 2;
        else
          if (vsync_delay_cnt_v = 0) then
            vs_o <= not(D8M_VSYNC_ACTIVE_POLARITY_1080P);
            vsync_delay_cnt_v := 0;
          else
            vsync_delay_cnt_v := vsync_delay_cnt_v - 1;
          end if;
        end if;
        if ((vcnt_s < 2) or (hcnt_s < 2)) then
          if (hsync_delay_cnt_v > 1) then
            de_o <= FALSE;
            hs_o <= D8M_HSYNC_ACTIVE_POLARITY_1080P;
          else
            hsync_delay_cnt_v := hsync_delay_cnt_v + 1;
            de_o <= TRUE;
            hs_o <= not(D8M_HSYNC_ACTIVE_POLARITY_1080P);
          end if;
        else
          hsync_delay_cnt_v := 0;
          de_o <= TRUE;
          hs_o <= not(D8M_HSYNC_ACTIVE_POLARITY_1080P);
        end if;
      end if;
      
      -- create pixels
      if ((vcnt_s < 4) or (hcnt_s < 4)) then  -- not enough lines / columns for reconstruction, yet
        rgb_pixel_o.r <= (others => '0');
        rgb_pixel_o.g <= (others => '0');
        rgb_pixel_o.b <= (others => '0');
      else
        if (line_id_s = '1') then
          pixel_pattern_v(1) := '1';
        else
          pixel_pattern_v(1) := '0';
        end if;
        if (color_id_s = '1') then
          pixel_pattern_v(0) := '1';
        else
          pixel_pattern_v(0) := '0';
        end if;
        pixel_diff_ud_v := pixel_diff_func(pixel_01_s,pixel_13_s);
        pixel_diff_lr_v := pixel_diff_func(pixel_05_s,pixel_09_s);
        
        case (pixel_pattern_v) is
          when "00" =>  -- center pixel is blue
            rgb_pixel_o.r <= pixel_02_s(camera_pixel_depth+1 downto 2) + pixel_04_s(camera_pixel_depth+1 downto 2) +
                             pixel_10_s(camera_pixel_depth+1 downto 2) + pixel_12_s(camera_pixel_depth+1 downto 2);
            if (pixel_diff_ud_v < pixel_diff_lr_v) then
              rgb_pixel_o.g <= pixel_03_s(camera_pixel_depth downto 1) + pixel_11_s(camera_pixel_depth downto 1); 
            elsif (pixel_diff_ud_v = pixel_diff_lr_v) then
              rgb_pixel_o.g <= pixel_06_s(camera_pixel_depth downto 1) + pixel_08_s(camera_pixel_depth downto 1); 
            else
              rgb_pixel_o.g <= pixel_03_s(camera_pixel_depth+1 downto 2) + pixel_06_s(camera_pixel_depth+1 downto 2) +
                               pixel_08_s(camera_pixel_depth+1 downto 2) + pixel_11_s(camera_pixel_depth+1 downto 2);
            end if;
            rgb_pixel_o.b <= pixel_07_s(camera_pixel_depth-1 downto 0);
          when "10" =>  -- center pixel is red
            rgb_pixel_o.r <= pixel_07_s(camera_pixel_depth-1 downto 0);
            if (pixel_diff_ud_v < pixel_diff_lr_v) then
              rgb_pixel_o.g <= pixel_03_s(camera_pixel_depth downto 1) + pixel_11_s(camera_pixel_depth downto 1); 
            elsif (pixel_diff_ud_v = pixel_diff_lr_v) then
              rgb_pixel_o.g <= pixel_06_s(camera_pixel_depth downto 1) + pixel_08_s(camera_pixel_depth downto 1); 
            else
              rgb_pixel_o.g <= pixel_03_s(camera_pixel_depth+1 downto 2) + pixel_06_s(camera_pixel_depth+1 downto 2) +
                               pixel_08_s(camera_pixel_depth+1 downto 2) + pixel_11_s(camera_pixel_depth+1 downto 2);
            end if;
            rgb_pixel_o.b <= pixel_02_s(camera_pixel_depth+1 downto 2) + pixel_04_s(camera_pixel_depth+1 downto 2) +
                             pixel_10_s(camera_pixel_depth+1 downto 2) + pixel_12_s(camera_pixel_depth+1 downto 2);
          when "01" =>  -- center pixel is green in a line of blues
            rgb_pixel_o.r <= pixel_03_s(camera_pixel_depth downto 1) + pixel_11_s(camera_pixel_depth downto 1);
            rgb_pixel_o.g <= pixel_07_s(camera_pixel_depth-1 downto 0);
            rgb_pixel_o.b <= pixel_06_s(camera_pixel_depth downto 1) + pixel_08_s(camera_pixel_depth downto 1);
          when "11" =>  -- center pixel is green in a line of reds
            rgb_pixel_o.r <= pixel_06_s(camera_pixel_depth downto 1) + pixel_08_s(camera_pixel_depth downto 1);
            rgb_pixel_o.g <= pixel_07_s(camera_pixel_depth-1 downto 0);
            rgb_pixel_o.b <= pixel_03_s(camera_pixel_depth downto 1) + pixel_11_s(camera_pixel_depth downto 1);
        end case;
      end if;
    end if;
  end process;

end behavioral;
