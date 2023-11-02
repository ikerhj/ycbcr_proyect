library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ycbcr_pack.all;

entity unsigned_multiplier_24 is
  port (
    a : in  std_logic_vector(23 downto 0);   -- low-active reset
    b : in  std_logic_vector(23 downto 0);
    c : out std_logic_vector(47 downto 0);
    clk : in std_logic
  );
end entity unsigned_multiplier_24;

-- Add sign logic to the multiplier

architecture Behavioral of unsigned_multiplier_24 is
    signal a_48bit : std_logic_vector(47 downto 0) := (others => '0');
    signal b_48bit : std_logic_vector(47 downto 0) := (others => '0');
    signal temp : std_logic_vector(47 downto 0);
    signal a_shifted : std_logic_vector(47 downto 0);  -- new signal

begin
    process (clk) is
    begin
        if rising_edge(clk) then
            a_48bit <= (47 downto a'length => '0') & a;
            b_48bit <= (47 downto b'length => '0') & b;
            temp <= (others => '0');
            a_shifted <= a_48bit;  -- initialize a_shifted with the value of a_48bit
            for i in 0 to 47 loop
                if b_48bit(i) = '1' then
                    temp <= std_logic_vector(unsigned(temp) + unsigned(a_shifted));
                end if;
                a_shifted <= a_shifted(46 downto 0) & '0';  -- shift right
            end loop;
            c <= temp;
        end if;
    end process;
end Behavioral;

