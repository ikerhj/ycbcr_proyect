library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package camera2hdmi_pack is
  
  ----------------------------------------------------------------------------
  -- Constants, specific to the general project, should not be changed 
  ----------------------------------------------------------------------------
  
  constant camera_pixel_depth : integer := 10;  -- depth of raw inputs
  constant video_color_depth : integer := 8;    -- depth of the rgb signals (must match connected output data width per color channel on dev. board, e.g., 8 for C5G or DE10-Std)
  constant coeff_width       : integer := 22;   -- width of the coefficients for the color space transformation
  
  ----------------------------------------------------------------------------
  -- Type definitions
  ----------------------------------------------------------------------------
  
  -- types used for the design
  
  type camera_rgb_pixel_t is
  record
    r : unsigned(camera_pixel_depth-1 downto 0);
    g : unsigned(camera_pixel_depth-1 downto 0);
    b : unsigned(camera_pixel_depth-1 downto 0);
  end record;
  
  type sync_signals_t is
    record
      hsync : std_logic;
      vsync : std_logic;
      csync : std_logic;
      de : std_logic;
    end record;
  
  type video_signals_t is
  record
    ch1 : std_logic_vector(video_color_depth-1 downto 0);
    ch2 : std_logic_vector(video_color_depth-1 downto 0);
    ch3 : std_logic_vector(video_color_depth-1 downto 0);
  end record;

end camera2hdmi_pack;


package body camera2hdmi_pack is

end camera2hdmi_pack;
