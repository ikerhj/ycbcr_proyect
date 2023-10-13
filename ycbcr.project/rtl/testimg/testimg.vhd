library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.camera2hdmi_pack.all;
use work.videotimings.all;
use work.d8m_timings.all;
use work.macros.all;

entity testimg is

  generic (
    -- default generics for 1080p
    -- test image generation only supports
    --   - one resolution with integer scaling, and
    --   - generics must ensure that test image is within de-frame
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

end testimg;

architecture behavioral of testimg is

  constant tst_img_xsize : natural := 320;
  constant tst_img_ysize : natural := 240;
  constant tst_img_color_depth : natural := 6;
  
  constant tst_img_xstart : natural := xstart + (xactive - xscale*tst_img_xsize)/2;
  constant tst_img_xstop : natural := xstart + xactive - (xactive - xscale*tst_img_xsize)/2;
  
  constant tst_img_ystart : natural := ystart + (yactive - yscale*tst_img_ysize)/2;
  constant tst_img_ystop : natural := ystart + yactive - (yactive - yscale*tst_img_ysize)/2;

  type bool_array2_t is array (0 to 2) of boolean;
  
  signal wr_xpos_s : natural range 0 to tst_img_xsize-1 := 0;
  signal wr_ypos_s : natural range 0 to tst_img_ysize-1 := 0;
  signal wr_rgb_pixel_s : camera_rgb_pixel_t := (others => to_unsigned(0,camera_pixel_depth));
  
  signal wraddr_s : std_logic_vector(16 downto 0);
  signal wr_pixel_valid_s, wren_trigger_s : boolean := FALSE;
  signal wren_gated_s : std_logic := '0';
  

  signal xpos_img_s : natural range 0 to tst_img_xsize-1 := 0;
  signal ypos_img_s : natural range 0 to tst_img_ysize-1 := 0;
  
  signal pos_img_de_s : bool_array2_t := (others => FALSE);  
  signal rdaddr_s : std_logic_vector(16 downto 0);
  signal rden_s : std_logic := '0';
  
  signal ram_data_in_s : std_logic_vector(3*tst_img_color_depth-1 downto 0);
  signal ram_data_out_s : std_logic_vector(3*tst_img_color_depth-1 downto 0);
  
  component pixelbinning is
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
  end component pixelbinning;
  
  component testimg_ram is
    port (
      data : in std_logic_vector(17 downto 0);
      rdaddress : in std_logic_vector(16 downto 0);
      rdclock : in std_logic;
      rden : in std_logic := '0';
      wraddress : in std_logic_vector(16 downto 0);
      wrclock : in std_logic := '1';
      wren : in std_logic := '0';
      q : out std_logic_vector(17 downto 0)
    );
  end component testimg_ram;

begin

  -- pixel binning for writing new images to ram
  pixelbinning_u : pixelbinning
    generic map(
      h_active_in => D8M_H_ACTIVE_1080P,
      h_active_out => tst_img_xsize,
      h_bin_factor => xscale,
      v_active_in => D8M_V_ACTIVE_1080P,
      v_active_out => tst_img_ysize,
      v_bin_factor => yscale
    ) port map(
      clk_i => tst_clk_i,
      nrst_i => tst_nrst_i,
      hs_i => tst_hs_i,
      vs_i => tst_vs_i,
      de_i => tst_de_i,
      rgb_pixel_i => tst_rgb_pixel_i,
      bypass_pixel_binning => TRUE,
      xpos_o => wr_xpos_s,
      ypos_o => wr_ypos_s,
      pixel_valid_o => wr_pixel_valid_s,
      rgb_pixel_o => wr_rgb_pixel_s
    );
  
  -- trigger process for writing a new image
  process (tst_clk_i,tst_nrst_i)
    type wrstate_t is (waiting, pretrigger, capturing, init);
    variable wrstate_v : wrstate_t := init;
  begin
    if (tst_nrst_i = '0') then
      wrstate_v := init;
      wren_trigger_s <= FALSE;
    elsif (rising_edge(tst_clk_i)) then
      case (wrstate_v) is
        when waiting =>
          if (tst_capture_ntrigger_i = '0') then
            wrstate_v := pretrigger;
          end if;
          wren_trigger_s <= FALSE;
        when pretrigger =>
          if (wr_xpos_s = 0 and wr_ypos_s = 0 and not(wr_pixel_valid_s)) then
            wrstate_v := capturing;
          end if;
          wren_trigger_s <= TRUE;
        when capturing =>
          if (wr_xpos_s = tst_img_xsize-1 and wr_ypos_s = tst_img_ysize-1 and wr_pixel_valid_s) then
            wrstate_v := init;
            wren_trigger_s <= FALSE;
          else
            wren_trigger_s <= TRUE;
          end if;
        when others =>
          if (tst_capture_ntrigger_i = '1') then
            wrstate_v := waiting;
          end if;
          wren_trigger_s <= FALSE;
      end case;
    end if;
  end process;
  
  -- image reading: create actual postion in test image
  process (vclk_i,rstn_i)
    variable x_rep_cnt_v : natural range 0 to 10 := 0;
    variable y_rep_cnt_v : natural range 0 to 6 := 0;
  begin
    if (rising_edge(vclk_i)) then
      if (xpos_i = 0) then
        x_rep_cnt_v := 0;
        xpos_img_s <= 0;
        if (ypos_i = 0) then
          y_rep_cnt_v := 0;
          ypos_img_s <= 0;
        elsif (ypos_i >= tst_img_ystart and ypos_i < tst_img_ystop) then
          if (y_rep_cnt_v = yscale) then
            ypos_img_s <= ypos_img_s + 1;
            y_rep_cnt_v := 1;
          else
            y_rep_cnt_v := y_rep_cnt_v + 1;
          end if;
        end if;
        pos_img_de_s(0) <= FALSE;
      elsif (xpos_i >= tst_img_xstart and xpos_i < tst_img_xstop) then
        if (x_rep_cnt_v = xscale) then
          xpos_img_s <= xpos_img_s + 1;
          x_rep_cnt_v := 1;
        else
          x_rep_cnt_v := x_rep_cnt_v + 1;
        end if;
        if (ypos_i >= tst_img_ystart and ypos_i < tst_img_ystop) then
          pos_img_de_s(0) <= TRUE;
        else
          pos_img_de_s(0) <= FALSE;
        end if;
      else
        x_rep_cnt_v := 0;
        xpos_img_s <= 0;
        pos_img_de_s(0) <= FALSE;
      end if;
      
      pos_img_de_s(1 to 2) <= pos_img_de_s(0 to 1);
      
      if (rstn_i = '0') then
        x_rep_cnt_v := 0;
        y_rep_cnt_v := 0;
        xpos_img_s <= 0;
        ypos_img_s <= 0;
        pos_img_de_s <= (others => FALSE);
      end if;
    end if;
  end process;
  
  -- write/read test image from rom
  wraddr_s <= to_unsigned_std_logic_vector(wr_xpos_s,9) & to_unsigned_std_logic_vector(wr_ypos_s,8);
  wren_gated_s <= to_std_logic(wren_trigger_s and wr_pixel_valid_s);
  rdaddr_s <= to_unsigned_std_logic_vector(xpos_img_s,9) & to_unsigned_std_logic_vector(ypos_img_s,8);
  rden_s <= to_std_logic(not(wren_trigger_s));
  ram_data_in_s(3*tst_img_color_depth-1 downto 2*tst_img_color_depth) <= std_logic_vector(wr_rgb_pixel_s.r(camera_pixel_depth-1 downto camera_pixel_depth - tst_img_color_depth));
  ram_data_in_s(2*tst_img_color_depth-1 downto   tst_img_color_depth) <= std_logic_vector(wr_rgb_pixel_s.g(camera_pixel_depth-1 downto camera_pixel_depth - tst_img_color_depth));
  ram_data_in_s(  tst_img_color_depth-1 downto                     0) <= std_logic_vector(wr_rgb_pixel_s.b(camera_pixel_depth-1 downto camera_pixel_depth - tst_img_color_depth));
  
  testimg_ram_u : testimg_ram -- two cycle delay: input and output register
    port map (
      wrclock => vclk_i,
      wraddress => wraddr_s,
      data => ram_data_in_s,
      wren => wren_gated_s,
      rdaddress => rdaddr_s,
      rdclock => vclk_i,
      rden => rden_s,
      q => ram_data_out_s
    );
  
  -- write output
  process (vclk_i,rstn_i)
  
  begin
    if (rising_edge(vclk_i)) then
      if (pos_img_de_s(2)) then
        -- red
        videodata_rgb_o.r(camera_pixel_depth-1 downto camera_pixel_depth-tst_img_color_depth) <= unsigned(ram_data_out_s(3*tst_img_color_depth-1 downto 2*tst_img_color_depth));
        for idx in tst_img_color_depth+1 to camera_pixel_depth loop
          videodata_rgb_o.r(camera_pixel_depth-idx) <= '0';
        end loop;
        
        -- green
        videodata_rgb_o.g(camera_pixel_depth-1 downto camera_pixel_depth-tst_img_color_depth) <= unsigned(ram_data_out_s(2*tst_img_color_depth-1 downto   tst_img_color_depth));
        for idx in tst_img_color_depth+1 to camera_pixel_depth loop
          videodata_rgb_o.g(camera_pixel_depth-idx) <= '0';
        end loop;
        
        -- blue
        videodata_rgb_o.b(camera_pixel_depth-1 downto camera_pixel_depth-tst_img_color_depth) <= unsigned(ram_data_out_s(  tst_img_color_depth-1 downto                     0));
        for idx in tst_img_color_depth+1 to camera_pixel_depth loop
          videodata_rgb_o.b(camera_pixel_depth-idx) <= '0';
        end loop;
      else
        videodata_rgb_o <= (others => to_unsigned(0,camera_pixel_depth));
      end if;
    end if;
  end process;

end behavioral;
