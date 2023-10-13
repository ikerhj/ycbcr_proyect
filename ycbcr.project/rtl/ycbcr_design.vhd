library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ycbcr_pack.all;


entity ycbcr_design is
  port (
    nrst      : in  std_logic;   -- low-active reset
    clk       : in  std_logic;
    pixel_in  : in  rgb_pixel_t;
    pixel_out : out ycbcr_pixel_t
  );
end entity ycbcr_design;


architecture behavioral of ycbcr_design is

  -- registers
  signal pixel_in_reg  : rgb_pixel_t;
  signal pixel_out_reg : ycbcr_pixel_t;

  type ycbcr_pixel_tmp_t is
  record
    y  : unsigned(ycbcr_color_depth+coeff_width+1 downto 0);
    cb : unsigned(ycbcr_color_depth+coeff_width+1 downto 0);
    cr : unsigned(ycbcr_color_depth+coeff_width+1 downto 0);
  end record;

  type coeff_array_type is array (0 to 2) of signed(coeff_width-1 downto 0);
  
  -- coefficients for the transformation
  constant coeff_y : coeff_array_type := (
    b"001001_10010001_01101000",  -- 0.299
    b"010010_11001000_10110100",  -- 0.587
    b"000011_10100101_11100011"   -- 0.114
  );

  constant coeff_cb : coeff_array_type := (
    b"111010_10011001_10110110",  -- -0.168736
    b"110101_01100110_01001001",  -- -0.331264
    b"001111_11111111_11111111"   -- 0.5
  );

  constant coeff_cr : coeff_array_type := (
    b"001111_11111111_11111111",  -- 0.5
    b"110010_10011010_00011011",  -- -0.418688
    b"111101_01100101_11100100"   -- -0.081312
  );                                                 

begin -- architecture

  ycbcr_computation : process (nrst, clk)
    variable pixel_tmp : ycbcr_pixel_tmp_t;
    variable offset    : unsigned(ycbcr_color_depth+coeff_width+1 downto 0);

  begin

    offset := (others => '0');
    offset(ycbcr_color_depth+coeff_width-2) := '1';

    if nrst = '0' then
      pixel_in_reg.r   <= (others => '0');
      pixel_in_reg.g   <= (others => '0');
      pixel_in_reg.b   <= (others => '0');
      pixel_out_reg.y  <= (others => '0');
      pixel_out_reg.cb <= (others => '0');
      pixel_out_reg.cr <= (others => '0');
    elsif rising_edge(clk) then
      -- input register
      pixel_in_reg <= pixel_in;

      -- compute
      pixel_tmp.y  := unsigned(signed("00"&pixel_in_reg.r)*coeff_y(0)
                      + signed("00"&pixel_in_reg.g)*coeff_y(1)
                      + signed("00"&pixel_in_reg.b)*coeff_y(2));
      
      pixel_tmp.cb := unsigned(signed('0'&pixel_in_reg.r)*coeff_cb(0)
                      + signed('0'&pixel_in_reg.g)*coeff_cb(1)
                      + signed('0'&pixel_in_reg.b)*coeff_cb(2)
                      + signed(offset));

      pixel_tmp.cr := unsigned(signed('0'&pixel_in_reg.r)*coeff_cr(0)
                      + signed('0'&pixel_in_reg.g)*coeff_cr(1)
                      + signed('0'&pixel_in_reg.b)*coeff_cr(2)
                      + signed(offset));

      -- output register
      pixel_out_reg.y  <= pixel_tmp.y(ycbcr_color_depth+coeff_width-2 downto coeff_width-1);
      pixel_out_reg.cb <= pixel_tmp.cb(ycbcr_color_depth+coeff_width-2 downto coeff_width-1);
      pixel_out_reg.cr <= pixel_tmp.cr(ycbcr_color_depth+coeff_width-2 downto coeff_width-1);
    end if;

  end process ycbcr_computation;

  pixel_out <= pixel_out_reg;

end architecture behavioral;
