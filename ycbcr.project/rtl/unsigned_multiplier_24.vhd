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
    -- AND gate instantiations
    gen_and_gates: for i in 0 to 23 generate
        gen_and_gates_inner: for j in 0 to 23 generate
            w(i*24+j) <= a(i) and b(j);
        end generate;
    end generate;

    -- Full adder instantiations and output assignments
    c(0) <= w(0);
    -- first iteration of the FA without cin
    FA: full_adder port map (
            fa => w((0)*12), 
            fb => w(12), 
            fcin =>  '0', 
            fs => sum(0), 
            fcout => sum(1)
        );

    
    gen_full_adders: for i in 2 to 46 generate
        FA: full_adder port map (
            fa => w((i-1)*12), 
            fb => w(i*12), 
            fcin =>  w((i-2)*12+11), 
            fs => sum(i), 
            fcout => sum(i+1)
        );
    end generate gen_full_adders;


    c <= sum;
end Behavioral;