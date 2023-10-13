library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ycbcr_pack.all;


entity ycbcr_top is
  port (
    nrst        : in  std_logic;  -- low-active reset
    clk         : in  std_logic;
    pixel_in_p  : in  rgb_pixel_t;
    pixel_out_p : out ycbcr_pixel_t
  );
end entity ycbcr_top;


architecture structural of ycbcr_top is

  component ycbcr_design is
    port (
      nrst      : in  std_logic;
      clk       : in  std_logic;
      pixel_in  : in  rgb_pixel_t;
      pixel_out : out ycbcr_pixel_t
    );
  end component ycbcr_design;

begin -- architecture
  
  ycbcr_top_i : ycbcr_design
    port map (
      nrst      => nrst,
      clk       => clk,
      pixel_in  => pixel_in_p,
      pixel_out => pixel_out_p
    );

end architecture structural;
