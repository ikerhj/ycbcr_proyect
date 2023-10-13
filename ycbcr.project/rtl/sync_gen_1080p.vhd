library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.videotimings.ALL;

entity sync_gen_1080p is

  port(
    vclk_i : in std_logic;
    rstn_i : in std_logic;
    xpos_o : out natural range 0 to 4095;
    ypos_o : out natural range 0 to 2047;
    hsync_o : out std_logic;
    vsync_o : out std_logic;
    csync_o : out std_logic;
    de_o : out std_logic
  );

end sync_gen_1080p;

architecture behavioral of sync_gen_1080p is

  -- counter
  signal h_cnt, xpos_s : natural range 0 to 4095 := 0;
  signal v_cnt, ypos_s : natural range 0 to 2047 := 0;
  
  -- local sync signals
  signal hs_s, vs_s, cs_s : std_logic := '1';
  signal de_s : std_logic := '0';
  
begin
  
  -- generate hs and cs
  process (vclk_i) begin
    if rising_edge(vclk_i) then
      xpos_s <= h_cnt;
      -- h_cnt
      if h_cnt < H_TOTAL_1080P-1 then
        h_cnt <= h_cnt + 1;
      else
        h_cnt <= 0;
      end if;
      
      -- hs_s
      hs_s <= not(HSYNC_ACTIVE_POLARITY_1080P);
      if h_cnt < H_SYNCLEN_1080P then
        hs_s <= HSYNC_ACTIVE_POLARITY_1080P;
      end if;
      
      -- cs
      if vs_s = VSYNC_ACTIVE_POLARITY_1080P then
        cs_s <= CSYNC_ACTIVE_POLARITY_1080P;
        if h_cnt > H_TOTAL_1080P - H_SYNCLEN_1080P - 1 then
          cs_s <= not(CSYNC_ACTIVE_POLARITY_1080P);
        end if;
      else
        cs_s <= not(CSYNC_ACTIVE_POLARITY_1080P);
        if h_cnt < H_SYNCLEN_1080P then
          cs_s <= CSYNC_ACTIVE_POLARITY_1080P;
        end if;
      end if;
      
      if rstn_i = '0' then
        h_cnt <= 0;
        hs_s <= not(HSYNC_ACTIVE_POLARITY_1080P);
        cs_s <= not(CSYNC_ACTIVE_POLARITY_1080P);
      end if;
    end if;
  end process;

  -- generate vs
  process (vclk_i) begin
    if rising_edge(vclk_i) then
      ypos_s <= v_cnt;
      
      -- v_cnt
      if h_cnt = H_TOTAL_1080P-1 then
        if v_cnt < V_TOTAL_1080P-1 then
          v_cnt <= v_cnt + 1;
        else
          v_cnt <= 0;
        end if;
      end if;
      
      -- vs
      vs_s <= not(VSYNC_ACTIVE_POLARITY_1080P);
      if v_cnt < V_SYNCLEN_1080P then
        vs_s <= VSYNC_ACTIVE_POLARITY_1080P;
      end if;
      
      if rstn_i = '0' then
        v_cnt <= 0;
        vs_s <= not(VSYNC_ACTIVE_POLARITY_1080P);
      end if;
    end if;
  end process;
  
  -- generate de_o
  process (vclk_i) begin
    if rising_edge(vclk_i) then
      if (h_cnt >= X_START_1080P) and (h_cnt < (X_START_1080P + H_ACTIVE_1080P)) and (v_cnt >= Y_START_1080P) and (v_cnt < (Y_START_1080P + V_ACTIVE_1080P)) then
        de_s <= DE_ACTIVE_POLARITY_1080P;
      else
        de_s <= not(DE_ACTIVE_POLARITY_1080P);
      end if;
      
      if rstn_i = '0' then
        de_s <= not(DE_ACTIVE_POLARITY_1080P);
      end if;
    end if;
  end process;

  -- outputs
  xpos_o <= xpos_s;
  ypos_o <= ypos_s;
  hsync_o <= hs_s;
  vsync_o <= vs_s;
  csync_o <= cs_s;
  de_o <= de_s;

end behavioral;
