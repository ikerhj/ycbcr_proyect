library ieee;
use ieee.std_logic_1164.all;

entity unsigned_multiplier_24 is
    port (
        a : in std_logic_vector(23 downto 0);
        b : in std_logic_vector(23 downto 0);
        c : out std_logic_vector(47 downto 0)
    );
end unsigned_multiplier_24;

architecture Behavioral of unsigned_multiplier_24 is
    signal w : std_logic_vector(575 downto 0);
    signal sum : std_logic_vector(47 downto 0);
    component ripple_carry_adder_48 is
        port (
            A : in std_logic;
            B : in std_logic;
            Cin : in std_logic;
            S : out std_logic;
            Cout : out std_logic
        );
    end component;
begin
    -- AND gate instantiations
    gen_and_gates: for i in 0 to 23 generate
        gen_and_gates_inner: for j in 0 to 23 generate
            w(i*24+j) <= a(i) and b(j);
        end generate;
    end generate;

    -- Full adder instantiations and output assignments
    c(0) <= w(0);
    gen_full_adders: for i in 1 to 47 generate
        FA: ripple_carry_adder_48 port map (w((i-1)*12), w(i*12), w((i-2)*12+11), sum(i), sum(i+1));
    end generate;

    c <= sum;
end Behavioral;