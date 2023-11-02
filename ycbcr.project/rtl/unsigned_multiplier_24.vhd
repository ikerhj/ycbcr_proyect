use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity unsigned_braun_multiplier_24 is
    port (
        a : in std_logic_vector(23 downto 0);
        b : in std_logic_vector(23 downto 0);
        c : out std_logic_vector(47 downto 0)
    );
end unsigned_braun_multiplier_24;

architecture Behavioral of unsigned_braun_multiplier_24 is
    type array_2d is array (23 downto 0, 23 downto 0) of std_logic_vector(47 downto 0);
    signal partial_products : array_2d;
    signal sum : array_2d;
begin
    gen_partial_products: for i in 0 to 23 generate
        for j in 0 to 23 generate
            process(b)
            begin
                if b(j) = '1' then
                    partial_products(i, j) <= std_logic_vector(shift_left(unsigned(a), i));
                else
                    partial_products(i, j) <= (others => '0');
                end if;
            end process;
        end generate;
    end generate gen_partial_products;

    gen_sum: for i in 0 to 23 generate
        for j in 0 to 23-i generate
            sum(i, j) <= partial_products(i, j) + partial_products(i, j+1);
        end generate;
    end generate gen_sum;

    c <= sum(0, 0);
end Behavioral;