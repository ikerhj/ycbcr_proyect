-- two fors one for the row and the other for the column
-- use a variable for the size of the column and row
-- Also take into account that the full adders are shiftedto by -1




library ieee;
use ieee.std_logic_1164.all;

entity unsigned_multiplier_24 is
    generic (
        WIDTH: integer := 24
    );
    port (
        a : in std_logic_vector(WIDTH-1 downto 0);
        b : in std_logic_vector(WIDTH-1 downto 0);
        c : out std_logic_vector(2*WIDTH downto 0)
    );
end unsigned_multiplier_24;

architecture Behavioral of unsigned_multiplier_24 is
    signal partials : std_logic_vector(2*WIDTH-1 downto 0) := (others => '0');
    component full_adder is
        port (
            fa : in std_logic;
            fb : in std_logic;
            fcin : in std_logic;
            fs : out std_logic;
            fcout : out std_logic
        );
    end component;
begin
    -- Generate partial products
    gen_partial_products: for i in 0 to WIDTH-1 generate
        gen_partial_products_inner: for j in 0 to WIDTH-1 generate
            partials(i*WIDTH+j) <= a(i) and b(j);
        end generate;
    end generate;

    -- Add partial products
    gen_adders: for i in 0 to WIDTH-2 generate
        gen_adders_inner: for j in 0 to WIDTH-2 generate
            FA: full_adder port map (
                fa => partials(i*WIDTH+j),
                fb => partials((i+1)*WIDTH+j),
                fcin => '0',
                fs => c(i*WIDTH+j),
                fcout => c(i*WIDTH+j+1)
            );
        end generate;
    end generate;

    -- Handle last bit separately
    c(2*WIDTH-1) <= partials(2*WIDTH-1);
end Behavioral;