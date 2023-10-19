library IEEE;
use IEEE.std_logic_1164.all;

entity half_adder_tb is
end entity;

architecture tb of half_adder_tb is
component half_adder is
Port ( 
	ha, hb : in STD_LOGIC;
	hs, hcout : out STD_LOGIC
	);
end component;

signal ha : std_logic:='0';
signal hb : std_logic:='0';
signal fcin : std_logic:='0';
signal hs, hcout : STD_LOGIC;

begin
 
uut : half_adder port map(
	ha =>ha, 
	hb =>hb,
	hs => hs, 
	hcout => hcout
	);

-- Stimulus process
stim_proc: process
begin
-- hold reset state for 100 ns.
wait for 100 ns;


ha <= '0';
hb <= '0';
wait for 100 ns;

ha <= '0';
hb <= '0';
wait for 100 ns;

ha <= '0';
hb <= '1';
wait for 100 ns;

ha <= '0';
hb <= '1';
wait for 100 ns;

ha <= '1';
hb <= '0';
wait for 100 ns;

ha <= '1';
hb <= '0';
wait for 100 ns;

ha <= '1';
hb <= '1';
wait for 100 ns;

ha <= '1';
hb <= '1';
wait for 100 ns;
wait;

end process;
end tb;