library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package videotimings is

  -- Parameters for 640x480@60Hz (800px x 525lines, pclk 25.2MHz -> 60Hz)
  constant HSYNC_ACTIVE_POLARITY_480P : std_logic := '0';
  constant VSYNC_ACTIVE_POLARITY_480P : std_logic := '0';
  constant CSYNC_ACTIVE_POLARITY_480P : std_logic := '0';
  constant DE_ACTIVE_POLARITY_480P    : std_logic := '1';
  
  constant H_SYNCLEN_480P    : integer := 96;
  constant H_BACKPORCH_480P  : integer := 48;
  constant H_ACTIVE_480P     : integer := 640;
  constant H_FRONTPORCH_480P : integer := 16;
  constant H_TOTAL_480P      : integer := (H_SYNCLEN_480P + H_BACKPORCH_480P + H_ACTIVE_480P + H_FRONTPORCH_480P);

  constant V_SYNCLEN_480P    : integer := 2;
  constant V_BACKPORCH_480P  : integer := 33;
  constant V_ACTIVE_480P     : integer := 480;
  constant V_FRONTPORCH_480P : integer := 10;
  constant V_TOTAL_480P      : integer := (V_SYNCLEN_480P + V_BACKPORCH_480P + V_ACTIVE_480P + V_FRONTPORCH_480P);

  constant X_START_480P : integer := H_SYNCLEN_480P + H_BACKPORCH_480P;
  constant Y_START_480P : integer := V_SYNCLEN_480P + V_BACKPORCH_480P;


  -- Parameters for 1280x800@60Hz (1680px x 831lines, pclk 83.764800MHz -> 60.00Hz)
  constant HSYNC_ACTIVE_POLARITY_800P : std_logic := '0';
  constant VSYNC_ACTIVE_POLARITY_800P : std_logic := '0';
  constant CSYNC_ACTIVE_POLARITY_800P : std_logic := '0';
  constant DE_ACTIVE_POLARITY_800P    : std_logic := '1';

  constant H_SYNCLEN_800P    : integer := 128;
  constant H_BACKPORCH_800P  : integer := 200;
  constant H_ACTIVE_800P     : integer := 1280;
  constant H_FRONTPORCH_800P : integer := 72;
  constant H_TOTAL_800P      : integer := (H_SYNCLEN_800P + H_BACKPORCH_800P + H_ACTIVE_800P + H_FRONTPORCH_800P);

  constant V_SYNCLEN_800P    : integer := 6;
  constant V_BACKPORCH_800P  : integer := 22;
  constant V_ACTIVE_800P     : integer := 800;
  constant V_FRONTPORCH_800P : integer := 3;
  constant V_TOTAL_800P      : integer := (V_SYNCLEN_800P + V_BACKPORCH_800P + V_ACTIVE_800P + V_FRONTPORCH_800P);

  constant X_START_800P : integer := H_SYNCLEN_800P + H_BACKPORCH_800P;
  constant Y_START_800P : integer := V_SYNCLEN_800P + V_BACKPORCH_800P;


  -- Parameters for 1920x1080@60Hz (2200px x 1125lines, pclk 148.500000MHz -> 60.00Hz)
  constant HSYNC_ACTIVE_POLARITY_1080P : std_logic := '1';
  constant VSYNC_ACTIVE_POLARITY_1080P : std_logic := '1';
  constant CSYNC_ACTIVE_POLARITY_1080P : std_logic := '0';
  constant DE_ACTIVE_POLARITY_1080P    : std_logic := '1';

  constant H_SYNCLEN_1080P    : integer := 44;
  constant H_BACKPORCH_1080P  : integer := 148;
  constant H_ACTIVE_1080P     : integer := 1920;
  constant H_FRONTPORCH_1080P : integer := 88;
  constant H_TOTAL_1080P      : integer := (H_SYNCLEN_1080P + H_BACKPORCH_1080P + H_ACTIVE_1080P + H_FRONTPORCH_1080P);

  constant V_SYNCLEN_1080P    : integer := 5;
  constant V_BACKPORCH_1080P  : integer := 36;
  constant V_ACTIVE_1080P     : integer := 1080;
  constant V_FRONTPORCH_1080P : integer := 4;
  constant V_TOTAL_1080P      : integer := (V_SYNCLEN_1080P + V_BACKPORCH_1080P + V_ACTIVE_1080P + V_FRONTPORCH_1080P);

  constant X_START_1080P : integer := H_SYNCLEN_1080P + H_BACKPORCH_1080P;
  constant Y_START_1080P : integer := V_SYNCLEN_1080P + V_BACKPORCH_1080P;

end videotimings;

package body videotimings is

end videotimings;
