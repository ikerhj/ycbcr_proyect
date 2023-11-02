library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity unsigned_multiplier_24_tb is
end entity unsigned_multiplier_24_tb;

architecture test of unsigned_multiplier_24_tb is
    component unsigned_multiplier_24 is
        port (
            a : in std_logic_vector(23 downto 0);
            b : in std_logic_vector(23 downto 0);
            c : out std_logic_vector(47 downto 0)
        );
    end component;

    signal a, b : std_logic_vector(23 downto 0);
    signal c : std_logic_vector(47 downto 0);
begin


    uut : unsigned_multiplier_24 port map ( a => a, b => b, c => c);  -- connect clock signal

    stimulus : process
    begin
        wait for 100ns;
        a <= x"000000";
        b <= x"000000";
        wait for 200ns;
        assert c = x"000000000000" report "Test Case 1 Failed" severity error;

        -- repeat for other test cases...
        a <= x"000000";
        b <= x"000000";
        wait for 200ns;
        assert c = x"000000000000" report "Test Case 1 Failed" severity error;

        a <= x"000001";
        b <= x"000001";
        wait for 200ns;
        assert c = x"000001000001" report "Test Case 2 Failed" severity error;

        a <= x"000005";
        b <= x"000007";
        wait for 200ns;
        assert c = x"000000000C" report "Test Case 3 Failed" severity error;
        
        a <= x"0000FF";
        b <= x"0000FF";
        wait for 200ns;
        assert c = x"0000FE01FF" report "Test Case 3 Failed" severity error;

        a <= x"7FFFFF";
        b <= x"7FFFFF";
        wait for 200ns;
        assert c = x"3FFFFE000001" report "Test Case 4 Failed" severity error;

        a <= x"FFFFFF";
        b <= x"FFFFFF";
        wait for 200ns;
        assert c = x"FE0000010001" report "Test Case 5 Failed" severity error;
        wait;
    end process stimulus;

end architecture test;