library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.macros.all;


entity reset_generator is
  generic(
    active_state : boolean := TRUE
  );
  port(
    clk_i : in std_logic;
    clk_en_i : in boolean;
    async_nrst_i : in std_logic;
    rst_o : out std_logic := to_std_logic(active_state)
  );
end reset_generator;

architecture Behavioral of reset_generator is

  signal rst_pre : std_logic := to_std_logic(active_state);

begin

  process (clk_i, async_nrst_i) begin
    if rising_edge(clk_i) then
      if clk_en_i then
        rst_o <= rst_pre;
        rst_pre <= to_std_logic(not active_state);
      end if;
    end if;
    if (async_nrst_i = '0') then
      rst_o <= to_std_logic(active_state);
      rst_pre <= to_std_logic(active_state);
    end if;
  end process;


end Behavioral;
