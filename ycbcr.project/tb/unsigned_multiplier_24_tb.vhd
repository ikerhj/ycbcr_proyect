library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity unsigned_multiplier_24_tb is
end entity unsigned_multiplier_24_tb;

architecture test of unsigned_multiplier_24_tb is
    component unsigned_multiplier_24 is
        port (
            clk : in std_logic;  -- add clock signal
            a : in std_logic_vector(23 downto 0);
            b : in std_logic_vector(23 downto 0);
            c : out std_logic_vector(47 downto 0)
        );
    end component;

    signal a, b : std_logic_vector(23 downto 0);
    signal c : std_logic_vector(47 downto 0);
    signal clk : std_logic := '0';  -- add clock signal
begin
    -- clock process
    clk_process : process
    begin
        wait for 50 ns;  -- adjust the time period as needed
        clk <= not clk;
    end process;


    uut : unsigned_multiplier_24 port map (clk => clk, a => a, b => b, c => c);  -- connect clock signal

    stimulus : process
    begin
        wait until rising_edge(clk);
        a <= x"000000";
        b <= x"000000";
        wait until rising_edge(clk);
        assert c = x"000000000000" report "Test Case 1 Failed" severity error;

        -- repeat for other test cases...
        a <= x"000000";
        b <= x"000000";
        wait until rising_edge(clk);
        assert c = x"000000000000" report "Test Case 1 Failed" severity error;

        a <= x"000001";
        b <= x"000001";
        wait until rising_edge(clk);
        assert c = x"000001000001" report "Test Case 2 Failed" severity error;

        a <= x"0000FF";
        b <= x"0000FF";
        wait until rising_edge(clk);
        assert c = x"0000FE01FF" report "Test Case 3 Failed" severity error;

        a <= x"7FFFFF";
        b <= x"7FFFFF";
        wait until rising_edge(clk);
        assert c = x"3FFFFE000001" report "Test Case 4 Failed" severity error;

        a <= x"FFFFFF";
        b <= x"FFFFFF";
        wait until rising_edge(clk);
        assert c = x"FE0000010001" report "Test Case 5 Failed" severity error;
        wait;
    end process stimulus;

end architecture test;