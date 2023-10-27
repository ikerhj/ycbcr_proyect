library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
 
entity ripple_carry_adder_48 is
Port ( A : in STD_LOGIC_VECTOR (47 downto 0);
B : in STD_LOGIC_VECTOR (47 downto 0);
Cin : in STD_LOGIC;
S : out STD_LOGIC_VECTOR (47 downto 0);
Cout : out STD_LOGIC);
end ripple_carry_adder_48;
 
architecture Behavioral of ripple_carry_adder_48 is
 
-- Full Adder VHDL Code Component Decalaration
component ripple_carry_adder_24
Port ( A : in STD_LOGIC_VECTOR (23 downto 0);
B : in STD_LOGIC_VECTOR (23 downto 0);
Cin : in STD_LOGIC;
S : out STD_LOGIC_VECTOR (23 downto 0);
Cout : out STD_LOGIC );
end component;
 
-- Intermediate Carry declaration
signal c1,c2: STD_LOGIC;
 
begin
 
-- Port Mapping Full Adder 4 times
RCA1: ripple_carry_adder_24 port map(A(23 downto 0),B(23 downto 0),Cin,S(23 downto 0),c1);
RCA2: ripple_carry_adder_24 port map(A(47 downto 24),B(47 downto 24),c1,S(47 downto 24),Cout);
 
end Behavioral;
