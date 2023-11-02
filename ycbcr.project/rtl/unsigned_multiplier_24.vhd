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


begin
   
    -- Use shifted_a as an actual parameter in the component instantiation

    -- Remove the sensitivity list and use a wait statement instead
    process (clk) is  -- assuming 'clk' is your clock signal
    begin
        if rising_edge(clk) then  -- process executes on the rising edge of the clock
            a_48bit <= (47 downto a'length => '0') & a;
            b_48bit <= (47 downto b'length => '0') & b;
            temp <= (others => '0');
            for i in 0 to 47 loop
                if b_48bit(i) = '1' then
                    temp <= std_logic_vector(unsigned(temp) + shift_left(unsigned(a_48bit), i));
                end if;
            end loop;
            c <= temp;
        end if;
    end process;
end Behavioral;

