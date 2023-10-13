library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ycbcr_pack.all;

entity half_adder is
  port (
    ha : in  std_logic;   -- low-active reset
    hb : in  std_logic;
    hs : out std_logic;
	 hcout	: out std_logic
  );
end entity half_adder;


architecture behavioral of half_adder is

begin
	hs	<= ha xor hb;
	hcout <= ha and hb;
end architecture behavioral;