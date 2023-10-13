library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.macros.all;


entity register_clk_resync is
  generic(
    reg_width : positive := 16;
    resync_stages :positive := 2
    
  );
  port(
    clk_i : in std_logic;
    clk_en_i : in boolean;
    nrst_i : in std_logic;
    reg_preset_i : in std_logic_vector(reg_width-1 downto 0) := (others => '0');
    reg_i : in std_logic_vector(reg_width-1 downto 0);
    reg_o: out std_logic_vector(reg_width-1 downto 0) := (others => '0')
  );
end register_clk_resync;

architecture clk_transfer of register_clk_resync is

  type resync_pipeline_t is array (0 to resync_stages-1) of std_logic_vector(reg_width-1 downto 0);

  signal resync_register : resync_pipeline_t := (others => (others => '0'));

begin

  process (clk_i) begin
    if rising_edge(clk_i) then
      if clk_en_i then
        for idx in resync_stages-1 downto 1 loop
          resync_register(idx) <= resync_register(idx-1);
        end loop;
        resync_register(0) <= reg_i;
      end if;
      if nrst_i = '0' then
        resync_register <= (others => reg_preset_i);
      end if;
    end if;
  end process;

  reg_o <= resync_register(resync_stages-1);

end clk_transfer;
