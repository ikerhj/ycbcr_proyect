library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ycbcr_pack.all;

entity signed_multiplier_24 is
  port (
    a : in  std_logic_vector(24 downto 0);   -- low-active reset
    b : in  std_logic_vector(24 downto 0);
	c : out std_logic_vector(24 downto 0);
  );
end entity signed_multiplier_24;

-- Add sign logic to the multiplier

architecture Behavioral of signed_multiplier_24 is
begin
    process(a, b)
        variable temp : signed(63 downto 0);
    begin
        temp := (others => '0');
        for i in 0 to 23 loop
            if b(i) = '1' then
            -- TASK: change the following type so it doesn't use the plus sign
                temp := temp + shift_left(a, i);
                if temp(49) /= c(49) then
                    c <= (others => c(49)); -- set to max or min value if overflow
                    exit;
                end if;
            end if;
        end loop;
        c <= temp;
    end process;
end Behavioral;
