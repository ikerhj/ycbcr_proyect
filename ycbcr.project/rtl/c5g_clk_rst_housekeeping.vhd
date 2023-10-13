library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.macros.all;

entity c5g_clk_rst_housekeeping is

  port (
    sys_clk_base_i : in std_logic;            -- 50MHz
    sys_arst_n_i : in std_logic;
    sys_clk_o : out std_logic := '0';         -- 50MHz (same as input)
    sys_srst_n_o : out std_logic := '0';
    
    d8m_clk_base_i : in std_logic;            -- 50MHz
    d8m_arst_n_i : in std_logic;
    d8m_clk_base_o : out std_logic := '0';    -- 20MHz
    d8m_pll_locked_o : out std_logic;
    d8m_srst_n_o : out std_logic := '0';
    
    d8m_mipi_clk_i : in std_logic;            -- 50MHz
    d8m_mipi_arst_n_i : in std_logic;
    d8m_mipi_clk_o : out std_logic := '0';    -- 50MHz
    d8m_mipi_srst_n_o : out std_logic := '0';
    
    vid_clk_base_i : in std_logic;            -- e.g. 148.5MHz
    vid_arst_n_i : in std_logic;
    vid_clk_o : out std_logic := '0';         -- e.g. 148.5MHz (same as input)
    vid_srst_n_o : out std_logic := '0'
  );

end entity c5g_clk_rst_housekeeping;

architecture housekeeping of c5g_clk_rst_housekeeping is
  
  --=======================================================
  --  DECLARATION OF COMPONENTS
  --=======================================================
  
  component d8m_pll is
    port (
      refclk : in  std_logic;
      rst : in  std_logic;
      outclk_0 : out  std_logic;
      locked : out  std_logic
    );
  end component d8m_pll;
  
  component d8m_mipi_clk_gate is
    port (
      inclk  : in  std_logic := 'X'; -- inclk
      outclk : out std_logic         -- outclk
    );
  end component d8m_mipi_clk_gate;
  
  component d8m_mipi_pll is
    port (
      refclk : in  std_logic;
      rst : in  std_logic;
      outclk_0 : out  std_logic;
      locked : out  std_logic
    );
  end component d8m_mipi_pll;

  component reset_generator is
    generic(
      active_state : boolean := TRUE
    );
    port(
      clk_i : in std_logic;
      clk_en_i : in boolean;
      async_nrst_i : in std_logic;
      rst_o : out std_logic := to_std_logic(active_state)
    );
  end component reset_generator;
  
  
  --=======================================================
  --  DECLARATION OF SIGNALS (REGS and WIRES)
  --=======================================================
  
  signal sys_arst_n_s : std_logic;
  signal sys_run_s : boolean := FALSE;

  signal d8m_arst_s : std_logic;
  signal d8m_clk_base_s : std_logic;
  signal d8m_pll_lock_s : std_logic;
  signal d8m_arst_n_post_lock_s : std_logic;
  
  signal d8m_mipi_arst_s : std_logic;
  signal d8m_mipi_clk_gated_s : std_logic;
  signal d8m_mipi_clk_base_s : std_logic;
  signal d8m_mipi_pll_lock_s : std_logic;
  signal d8m_mipi_arst_n_post_lock_s : std_logic;

begin
  
  --=======================================================
  --  System (NIOS II)
  --=======================================================
  
  process (sys_clk_base_i)
    variable boot_delay_v : natural range 0 to 1023 := 1023;
  begin
    if rising_edge(sys_clk_base_i) then
      if boot_delay_v = 0 then
        sys_run_s <= TRUE; -- always running cpu
      else
        sys_run_s <= FALSE;
        boot_delay_v := boot_delay_v - 1;
      end if;
    end if;
  end process;
  
  sys_arst_n_s <= to_std_logic(sys_run_s) and sys_arst_n_i;
  
  sys_nrst_syncr_u : reset_generator
    generic map (
      active_state => FALSE
    )
    port map (
      clk_i => sys_clk_base_i,
      clk_en_i => sys_run_s,
      async_nrst_i => sys_arst_n_s,
      rst_o => sys_srst_n_o
    );
  
  sys_clk_o <= sys_clk_base_i;
  
  --=======================================================
  --  D8M
  --=======================================================
  
  d8m_arst_s <= not d8m_arst_n_i;

  d8m_pll_u : d8m_pll
    port map(
      refclk => d8m_clk_base_i, -- 50MHz
      rst => d8m_arst_s,
      outclk_0 => d8m_clk_base_s, -- 20MHz
      locked => d8m_pll_lock_s
    );
  
  d8m_arst_n_post_lock_s <= d8m_arst_n_i and d8m_pll_lock_s;
  d8m_pll_locked_o <= d8m_pll_lock_s;
  
  d8m_nrst_syncr_u : reset_generator
    generic map (
      active_state => FALSE
    )
    port map (
      clk_i => d8m_clk_base_s,
      clk_en_i => TRUE,
      async_nrst_i => d8m_arst_n_post_lock_s,
      rst_o => d8m_srst_n_o
    );
  
  d8m_clk_base_o <= d8m_clk_base_s;
  
  --=======================================================
  --  D8M MIPI
  --=======================================================

  d8m_mipi_arst_s <= not(d8m_mipi_arst_n_i and d8m_pll_lock_s);
  
  d8m_mipi_clk_gate_u : d8m_mipi_clk_gate
    port map (
      inclk  => d8m_mipi_clk_i,
      outclk => d8m_mipi_clk_gated_s
    );
  
  d8m_mipi_pll_u : d8m_mipi_pll
    port map(
      refclk => d8m_mipi_clk_gated_s, -- 50MHz
      rst => d8m_mipi_arst_s,
      outclk_0 => d8m_mipi_clk_base_s,  -- 50MHz
      locked => d8m_mipi_pll_lock_s
    );
  
  d8m_mipi_arst_n_post_lock_s <= d8m_mipi_arst_n_i and d8m_mipi_pll_lock_s;
  
  d8m_mipi_nrst_syncr_u : reset_generator
    generic map (
      active_state => FALSE
    )
    port map (
      clk_i => d8m_mipi_clk_base_s,
      clk_en_i => TRUE,
      async_nrst_i => d8m_mipi_arst_n_post_lock_s,
      rst_o => d8m_mipi_srst_n_o
    );
  
  d8m_mipi_clk_o <= d8m_mipi_clk_base_s;
  --=======================================================
  --  Video
  --=======================================================
  
  vid_nrst_syncr_u : reset_generator
    generic map (
      active_state => FALSE
    )
    port map (
      clk_i => vid_clk_base_i,
      clk_en_i => TRUE,
      async_nrst_i => vid_arst_n_i,
      rst_o => vid_srst_n_o
    );
  
  vid_clk_o <= vid_clk_base_i;


end housekeeping;
