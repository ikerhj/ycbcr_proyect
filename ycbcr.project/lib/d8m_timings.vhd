library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package d8m_timings is

  -- Parameters for 1920x1080@15Hz
  constant D8M_HSYNC_ACTIVE_POLARITY_1080P : std_logic := '0';
  constant D8M_VSYNC_ACTIVE_POLARITY_1080P : std_logic := '0';

  constant D8M_H_SYNCLEN_1080P : natural := 528;
  constant D8M_H_ACTIVE_1080P  : natural := 1920;
  constant D8M_V_SYNCLEN_1080P : natural := 10; -- a bit more than 10
  constant D8M_V_ACTIVE_1080P  : natural := 1080;
  
  constant D8M_H_CNT_WIDTH : natural := 15;
  constant D8M_V_CNT_WIDTH : natural := 10;

end d8m_timings;

package body d8m_timings is

end d8m_timings;
