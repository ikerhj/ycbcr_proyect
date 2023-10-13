library IEEE;
use IEEE.std_logic_1164.all;

entity full_adder_tb is
end entity;

architecture tb of full_adder_tb is
component full_adder is
Port ( fa, fb, fcin : in STD_LOGIC;
fs, fcout : out STD_LOGIC);
end component;

signal fa : std_logic:='0';
signal fb : std_logic:='0';
signal fcin : std_logic:='0';
signal fs, fcout : STD_LOGIC;

begin
 
uut : full_adder port map(
	fa =>fa, 
	fb =>fb,
	fcin => fcin, 
	fs => fs, 
	fcout => fcout
	);

 -- Stimulus process
 stim_proc: process
 begin
 -- hold reset state for 100 ns.
 wait for 100 ns;


fa <= '0';
fb <= '0';
fcin <= '0';
wait for 10 ns;

fa <= '0';
fb <= '0';
fcin <= '1';
wait for 10 ns;

fa <= '0';
fb <= '1';
fcin <= '0';
wait for 10 ns;

fa <= '0';
fb <= '1';
fcin <= '1';
wait for 10 ns;

fa <= '1';
fb <= '0';
fcin <= '0';
wait for 10 ns;

fa <= '1';
fb <= '0';
fcin <= '1';
wait for 10 ns;

fa <= '1';
fb <= '1';
fcin <= '0';
wait for 10 ns;

fa <= '1';
fb <= '1';
fcin <= '1';
wait for 10 ns;
wait;

end process;
end tb;