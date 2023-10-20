library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
 
entity 8_ripple_carry_adder is
Port ( A : in STD_LOGIC_VECTOR (7 downto 0);
B : in STD_LOGIC_VECTOR (7 downto 0);
Cin : in STD_LOGIC;
S : out STD_LOGIC_VECTOR (7 downto 0);
Cout : out STD_LOGIC);
end 8_ripple_carry_adder;
 
architecture Behavioral of 8_ripple_carry_adder is
 
-- Full Adder VHDL Code Component Decalaration
component full_adder
Port ( A : in STD_LOGIC;
B : in STD_LOGIC;
Cin : in STD_LOGIC;
S : out STD_LOGIC;
Cout : out STD_LOGIC);
end component;
 
-- Intermediate Carry declaration
signal c1,c2,c3,c4,c5,c6,c7: STD_LOGIC;
 
begin
 
-- Port Mapping Full Adder 4 times
FA1: full_adder port map( A(0), B(0), Cin, S(0), c1);
FA2: full_adder port map( A(1), B(1), c1, S(1), c2);
FA3: full_adder port map( A(2), B(2), c2, S(2), c3);
FA4: full_adder port map( A(3), B(3), c3, S(3), c4);
FA5: full_adder port map( A(4), B(4), c4, S(4), c5);
FA6: full_adder port map( A(5), B(5), c5, S(5), c6);
FA7: full_adder port map( A(6), B(6), c6, S(6), c7);
FA8: full_adder port map( A(7), B(7), c7, S(7), Cout);
 
end Behavioral;
