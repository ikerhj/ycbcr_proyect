library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ycbcr_pack.all;

entity full_adder is
  port (
    fa : in  std_logic;   -- low-active reset
    fb : in  std_logic;
	 fcin : in std_logic;
    fs : out std_logic;
	 fcout	: out std_logic
  );
end entity full_adder;


architecture behavioral of full_adder is

component half_adder is 
	port (
		ha : in  std_logic;   -- low-active reset
		hb : in  std_logic;
		hs : out std_logic;
		hcout	: out std_logic
	);
end component;

-- Signals for 
signal s0,s1,s2:std_logic;

begin
	U1: half_adder port map (ha=>fa, hb=>fb, hs=>s0, hcout=>s1);
	U2: half_adder port map (ha=>s0, hb=>fcin, hs=>fs, hcout=>s2);
	fcout <= s1 or s2;
	
end architecture behavioral;