library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity braun_multiplier is
    port (
        a : in std_logic_vector(23 downto 0);
        b : in std_logic_vector(23 downto 0);
        c : out std_logic_vector(47 downto 0)
    );
end braun_multiplier;

architecture Behavioral of braun_multiplier is
    signal partial_products : std_logic_vector(47 downto 0);
    signal sum : std_logic_vector(47 downto 0);
begin
    gen_partial_products: for i in 0 to 23 generate
        partial_products(2*i downto 2*i) <= std_logic_vector(shift_left(unsigned(a), i) when b(i) = '1' else (others => '0'));
    end generate gen_partial_products;

    gen_sum: for i in 0 to 47 generate
        sum(i) <= or(partial_products(i downto i) & partial_products(i+1 downto i+1));
    end generate gen_sum;

    c <= sum;
end Behavioral;
