-- two fors one for the row and the other for the column
-- use a variable for the size of the column and row
-- Also take into account that the full adders are shiftedto by -1




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
    signal w : std_logic_vector(575 downto 0) := (others => '0');
    signal sum : std_logic_vector(47 downto 0) := (others => '0');
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
    FAF: full_adder port map (
            fa => w(0), 
            fb => w(12), 
            fcin =>  '0', 
            fs => sum(1), 
            fcout => sum(2)
        );

     -- second iteration of the FA without cin
     FAS: full_adder port map (
        fa => w(12), 
        fb => w(24), 
        fcin =>  sum(0), 
        fs => sum(1), 
        fcout => sum(2)
    );


    
    gen_full_adders: for i in 2 to 45 generate
    FA: full_adder port map (
        fa => w(i*12), 
        fb => w((i+1)*12), 
        fcin =>  sum(i), 
        fs => sum(i+1), 
        fcout => sum(i+2)
    );
    end generate gen_full_adders;

    FASL: full_adder port map (
        fa => w((45)*12), 
        fb => w(46*12), 
        fcin =>  sum(45), 
        fs => sum(46), 
        fcout => open
    );
    FAL: full_adder port map (
        fa => w((46)*12), 
        fb => w(47*12), 
        fcin =>  sum(46), 
        fs => sum(47), 
        fcout => open
    );

    c <= sum;
end Behavioral;