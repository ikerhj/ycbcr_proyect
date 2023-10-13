-------------------------------------------------------------------------------
-- File       : rtl_cfg.vhd
-- Created    : 2022-11-01
-- Description: Useful functions
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package rtl_cfg is

  ----------------------------------------------------------------------------
  -- Version of RTL code
  ----------------------------------------------------------------------------
  constant VERSION_MAIN : integer := 1; 
  constant VERSION_SUB  : integer := 00; 
  
  constant VERSION_MAIN_LENGTH : integer :=  4;
  constant VERSION_SUB_LENGTH  : integer := 12;

end rtl_cfg;

package body rtl_cfg is

 end rtl_cfg;
