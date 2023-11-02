library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ycbcr_pack.all;

entity unsigned_multiplier_24 is
  port (
    a : in  std_logic_vector(23 downto 0);   -- low-active reset
    b : in  std_logic_vector(23 downto 0);
    c : out std_logic_vector(47 downto 0)
  );
end entity unsigned_multiplier_24;

-- Add sign logic to the multiplier

architecture Behavioral of unsigned_multiplier_24 is
    signal a_48bit : std_logic_vector(47 downto 0) := (others => '0');
    signal b_48bit : std_logic_vector(47 downto 0) := (others => '0');
    signal temp : std_logic_vector(47 downto 0);
    signal sum : std_logic_vector(47 downto 0) := (others => '0');
    signal carryOut : std_logic := '0';
    signal carryIn : std_logic;



    component ripple_carry_adder_48 is
        port (
            A : in  std_logic_vector(47 downto 0);
            B : in  std_logic_vector(47 downto 0);
            Cin : in STD_LOGIC;
            S : out STD_LOGIC_VECTOR (47 downto 0);
            Cout : out STD_LOGIC);
    end component;

    
    begin
        a_48bit <= (47 downto a'length => '0') & a;
        b_48bit <= (47 downto b'length => '0') & b;
        -- Outtside of the process, only combinational logic inside the process
        RCA1: ripple_carry_adder_48 port map (temp, shifted_a_var, carryIn, sum, carryOut);
        
    
    process(a_48bit, b_48bit)
        variable shifted_a_var : std_logic_vector(47 downto 0);
    begin
        shifted_a_var := a_48bit;
        temp <= (others => '0');
        carryIn <= '0';
        for i in 0 to 47 loop
            if b_48bit(i) = '1' then
                temp <= sum;
                carryIn <= '1';
            end if;
            shifted_a_var := shifted_a_var(46 downto 0) & '0';
        end loop;
        c <= temp;
    end process;
        
end Behavioral;

