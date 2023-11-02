library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity unsigned_multiplier_24 is
    port (
        a : in std_logic_vector(23 downto 0);
        b : in std_logic_vector(23 downto 0);
        c : out std_logic_vector(47 downto 0)
    );
end unsigned_multiplier_24;

architecture Behavioral of unsigned_multiplier_24 is
    signal partial_products : std_logic_vector(47 downto 0);
    signal sum : std_logic_vector(47 downto 0);
begin
    process(a, b)
    begin
        sum <= (others => '0');
        for i in 0 to 23 loop
            if b(i) = '1' then
                partial_products <= std_logic_vector(shift_left(unsigned(a), i) & (23 downto 0 => '0'));
                sum <= std_logic_vector(unsigned(sum) + unsigned(partial_products));
            end if;
        end loop;
    end process;

    c <= sum;
end Behavioral;