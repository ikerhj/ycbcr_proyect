library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package ycbcr_pack is
  
  ----------------------------------------------------------------------------
  -- Constants, specific to the general project, should not be changed 
  ----------------------------------------------------------------------------
  
  constant rgb_color_depth   : integer := 16;  -- depth of the rgb input signals
  constant ycbcr_color_depth : integer := 16;  -- depth of the ycbcr output signals
  constant coeff_width       : integer := 22;  -- width of the coefficients for the color space transformation
  
  ----------------------------------------------------------------------------
  -- Type definitions
  ----------------------------------------------------------------------------
  
  -- types used for the design
  type rgb_pixel_t is
  record
    r : unsigned(rgb_color_depth-1 downto 0);
    g : unsigned(rgb_color_depth-1 downto 0);
    b : unsigned(rgb_color_depth-1 downto 0);
  end record;

  type ycbcr_pixel_t is
  record
    y  : unsigned(ycbcr_color_depth-1 downto 0);
    cb : unsigned(ycbcr_color_depth-1 downto 0);
    cr : unsigned(ycbcr_color_depth-1 downto 0);
  end record;

end ycbcr_pack;


package body ycbcr_pack is

end ycbcr_pack;
