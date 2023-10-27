library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
 
entity ripple_carry_adder_24 is
Port ( A : in STD_LOGIC_VECTOR (23 downto 0);
B : in STD_LOGIC_VECTOR (23 downto 0);
Cin : in STD_LOGIC;
S : out STD_LOGIC_VECTOR (23 downto 0);
Cout : out STD_LOGIC);
end ripple_carry_adder_24;
 
architecture Behavioral of ripple_carry_adder_24 is
 
-- Full Adder VHDL Code Component Decalaration
component ripple_carry_adder_8
Port ( A : in STD_LOGIC_VECTOR (7 downto 0);
B : in STD_LOGIC_VECTOR (7 downto 0);
Cin : in STD_LOGIC;
S : out STD_LOGIC_VECTOR (7 downto 0);
Cout : out STD_LOGIC; );
end component;
 
-- Intermediate Carry declaration
signal c1,c2,c3: STD_LOGIC;
 
begin
 
-- Port Mapping Full Adder 4 times
RCA1: ripple_carry_adder_8 port map(A(7 downto 0),B(7 downto 0),Cin,S(7 downto 0),c1);
RCA2: ripple_carry_adder_8 port map(A(15 downto 8),B(15 downto 8),c1,S(15 downto 8),c2);
RCA3: ripple_carry_adder_8 port map(A(23 downto 16),B(23 downto 16),c2,S(23 downto 16),Cout);
 
end Behavioral;
