library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ripple_carry_adder_8_tb is
end ripple_carry_adder_8_tb;

architecture behavior of ripple_carry_adder_8_tb is
    -- Instantiate the 8_ripple_carry_adder component
    component ripple_carry_adder_8 is
    Port ( A : in STD_LOGIC_VECTOR (7 downto 0);
           B : in STD_LOGIC_VECTOR (7 downto 0);
           Cin : in STD_LOGIC;
           S : out STD_LOGIC_VECTOR (7 downto 0);
           Cout : out STD_LOGIC);
    end component;

    -- Signals for the test bench
    signal A_s, B_s, S_s : STD_LOGIC_VECTOR (7 downto 0);
    signal Cin_s, Cout_s : STD_LOGIC;

begin
    -- Instantiate the 8_ripple_carry_adder component
    DUT: ripple_carry_adder_8 port map (A_s, B_s, Cin_s, S_s, Cout_s);

    -- Process to provide stimulus to the 8_ripple_carry_adder component
    stim_proc: process
    begin
        -- Provide different test vectors
        A_s <= "00000000";
        B_s <= "00000000";
        Cin_s <= '0';
        wait for 10 ns;

        A_s <= "00000001";
        B_s <= "00000001";
        Cin_s <= '0';
        wait for 10 ns;

        A_s <= "11111111";
        B_s <= "11111111";
        Cin_s <= '1';
        wait for 10 ns;

        -- Add more test vectors as needed

        -- End the simulation
        wait;
    end process;
end behavior;
