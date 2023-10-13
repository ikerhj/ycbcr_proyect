-------------------------------------------------------------------------------
-- File       : macros.vhd
-- Created    : 2003-03-07
-- Description: Useful functions
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package macros is

  ----------------------------------------------------------------------------
  -- Taktrate in Hertz
  ----------------------------------------------------------------------------
  constant CLK_RATE : integer := 40000000;  -- 40 MHz 

  ----------------------------------------------------------------------------
  -- Umwandlungsfunktionen von binaer und integer nach 7-Segment
  -- Eingaben :
  --      bin - Binaere Eingabewert; '0000' = 0, '0001' = 1, ... '1111' = 15
  --      int - Ganzzahliger Eingabewert von 0 bis 15
  -- Rueckgabewert :
  --            Signale fuer die 7-Segmentanzeige;
  --            seg(0) -> a, seg(1) -> b, ... seg(6) -> g;
  --            also seg(6 downto 0) -> (g,f,e,d,c,b,a);
  --            '0' fuer aus, '1' fuer an
  ----------------------------------------------------------------------------
  function bin2seg (bin : std_logic_vector(3 downto 0))
    return std_logic_vector;
  function int2seg (int : integer range 0 to 15)
    return std_logic_vector;
  ----------------------------------------------------------------------------
  -- Umwandlung von 7-Segment nach binaer und integer.
  -- Ein- und Ausgaben entsprechend bin2seg
  ----------------------------------------------------------------------------
  function seg2bin (seg : std_logic_vector(6 downto 0))
    return std_logic_vector;
  function seg2int (seg : std_logic_vector(6 downto 0))
    return integer;

  ----------------------------------------------------------------------------
  -- Umwandlung in std_logic_vector und integer
  ----------------------------------------------------------------------------
  function to_unsigned_std_logic_vector (arg : integer; size : integer) return std_logic_vector;
  function to_signed_std_logic_vector (arg   : integer; size : integer) return std_logic_vector;

  function to_unsigned_integer (arg : std_logic_vector) return integer;
  function to_signed_integer (arg   : std_logic_vector) return integer;

  ----------------------------------------------------------------------------
  -- Umwandlung von boolean nach std_logic
  ----------------------------------------------------------------------------
  function to_std_logic (constant i : boolean) return std_logic;
  function to_boolean (constant s : std_logic) return boolean;
  
  ----------------------------------------------------------------------------
  -- flip functions
  ----------------------------------------------------------------------------
  function flipvector (vector : std_logic_vector) return std_logic_vector;
  
  ----------------------------------------------------------------------------
  -- Maximalwert, Minimalwert
  ----------------------------------------------------------------------------
  function maximum (a, b : integer) return integer;
  function minimum (a, b : integer) return integer;

  ----------------------------------------------------------------------------
  -- Funktionen zum Dividieren und anschliessendem Runden von Ganzzahlen
  ----------------------------------------------------------------------------
  -- Aufrunden von a/b
  function div_ceil (a, b  : integer) return integer;
  -- Abrunden von a/b
  function div_floor (a, b : integer) return integer;
  -- Normales Runden von a/b
  function div_round (a, b : integer) return integer;

  ----------------------------------------------------------------------------
  -- Funktionen zum Berechnen des dyadischen Logarithmus
  -- Arbeitet korrekt bis bis 32 Bit
  ----------------------------------------------------------------------------
  -- Aufrunden von log2; benoetigt man zum Berechnen der Anzahl der Bits
  -- um 0 bis (x-1) binaer darzustellen,
  -- oder die noetige Anzahl der Bits fuer x Zustaende
  function log2_ceil(x  : positive) return natural;
  -- Abrunden von log2
  function log2_floor(x : positive) return natural;

  ----------------------------------------------------------------------------
  -- Gray code Konvertierung
  -- Wird fuer asynchrone FIFOs benoetigt
  ----------------------------------------------------------------------------
  -- Konvertiert binaer in gray
  function bin2gray (bin  : std_logic_vector) return std_logic_vector;
  -- Konvertiert gray in binaer
  function gray2bin (gray : std_logic_vector) return std_logic_vector;

  ----------------------------------------------------------------------------
  -- Toggle signals
  ----------------------------------------------------------------------------
  procedure toggle (signal s : inout std_logic);
  procedure toggle (signal s : inout boolean);

end macros;

package body macros is

  function bin2seg (bin : std_logic_vector(3 downto 0))
    return std_logic_vector is
  begin  -- bin2seg
    case bin is
      when x"0"   => return "0111111";
      when x"1"   => return "0000110";
      when x"2"   => return "1011011";
      when x"3"   => return "1001111";
      when x"4"   => return "1100110";
      when x"5"   => return "1101101";
      when x"6"   => return "1111101";
      when x"7"   => return "0000111";
      when x"8"   => return "1111111";
      when x"9"   => return "1101111";
      when x"A"   => return "1110111";
      when x"B"   => return "1111100";
      when x"C"   => return "0111001";
      when x"D"   => return "1011110";
      when x"E"   => return "1111001";
      when x"F"   => return "1110001";
      when others => return "0000000";
    end case;
  end bin2seg;

  function int2seg (int : integer range 0 to 15)
    return std_logic_vector is
  begin  -- int2seg
    case int is
      when 0  => return "0111111";
      when 1  => return "0000110";
      when 2  => return "1011011";
      when 3  => return "1001111";
      when 4  => return "1100110";
      when 5  => return "1101101";
      when 6  => return "1111101";
      when 7  => return "0000111";
      when 8  => return "1111111";
      when 9  => return "1101111";
      when 10 => return "1110111";
      when 11 => return "1111100";
      when 12 => return "0111001";
      when 13 => return "1011110";
      when 14 => return "1111001";
      when 15 => return "1110001";
    end case;
  end int2seg;

  function seg2bin (seg : std_logic_vector(6 downto 0))
    return std_logic_vector is
  begin  -- seg2bin
    case seg is
      when "0111111" => return x"0";
      when "0000110" => return x"1";
      when "1011011" => return x"2";
      when "1001111" => return x"3";
      when "1100110" => return x"4";
      when "1101101" => return x"5";
      when "1111101" => return x"6";
      when "0000111" => return x"7";
      when "1111111" => return x"8";
      when "1101111" => return x"9";
      when "1110111" => return x"A";
      when "1111100" => return x"B";
      when "0111001" => return x"C";
      when "1011110" => return x"D";
      when "1111001" => return x"E";
      when "1110001" => return x"F";
      when others    => return "XXXX";
    end case;
  end seg2bin;

  function seg2int (seg : std_logic_vector(6 downto 0))
    return integer is
  begin  -- seg2int
    case seg is
      when "0111111" => return 0;
      when "0000110" => return 1;
      when "1011011" => return 2;
      when "1001111" => return 3;
      when "1100110" => return 4;
      when "1101101" => return 5;
      when "1111101" => return 6;
      when "0000111" => return 7;
      when "1111111" => return 8;
      when "1101111" => return 9;
      when "1110111" => return 10;
      when "1111100" => return 11;
      when "0111001" => return 12;
      when "1011110" => return 13;
      when "1111001" => return 14;
      when "1110001" => return 15;
      when others    => return -1;
    end case;
  end seg2int;

  function to_unsigned_std_logic_vector (arg : integer; size : integer) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(arg, size));
  end to_unsigned_std_logic_vector;

  function to_signed_std_logic_vector (arg : integer; size : integer) return std_logic_vector is
  begin
    return std_logic_vector(to_signed(arg, size));
  end to_signed_std_logic_vector;

  function to_unsigned_integer (arg : std_logic_vector) return integer is
  begin
    return to_integer(unsigned(arg));
  end to_unsigned_integer;
  
  function to_signed_integer (arg   : std_logic_vector) return integer is
  begin
    return to_integer(signed(arg));
  end to_signed_integer;

  function to_std_logic (constant i : boolean) return std_logic is
  begin  -- to_std_logic
    if i then
      return '1';
    else
      return '0';
    end if;
  end to_std_logic;

  function to_boolean (constant s : std_logic) return boolean is
  begin  -- to_boolean
    if s = '1' then
      return TRUE;
    else
      return FALSE;
    end if;
  end to_boolean;

  function flipvector (vector : std_logic_vector) return std_logic_vector is
    variable return_vector : std_logic_vector (vector'high downto vector'low);
  begin
    for i in vector'low to vector'high loop
      return_vector(vector'high - i + vector'low) := vector(i);
    end loop;
    return return_vector;
  end flipvector;

  function maximum (a, b : integer) return integer is
  begin
    if a > b then
      return a;
    else
      return b;
    end if;
  end maximum;

  function minimum (a, b : integer) return integer is
  begin
    if a > b then
      return b;
    else
      return a;
    end if;
  end minimum;

  function div_ceil (a, b : integer) return integer is
  begin
    if a > 0 then
      return (a + b - 1) / b;
    else
      return -((-a + b - 1) / b);
    end if;
  end div_ceil;

  function div_floor (a, b : integer) return integer is
  begin
    return a / b;
  end div_floor;

  function div_round (a, b : integer) return integer is
  begin
    if a > 0 then
      return (a + b/2) / b;
    else
      return -((-a + b/2) / b);
    end if;
  end div_round;

  function log2_floor (x : positive) return natural is
  begin
    if x <= 1 then
      return 0;
    else
      return log2_floor (x / 2) + 1;
    end if;
  end log2_floor;

  function log2_ceil (x : positive) return natural is
  begin
    if x <= 1 then
      return 0;
    else
      return log2_floor (x - 1) + 1;
    end if;
  end log2_ceil;

  function recursive_xor (x : std_logic_vector) return std_logic is
    variable split : integer := x'length / 2;
  begin  -- recursive_xor
    if x'length = 1 then
      return x(x'right);
    else
      return recursive_xor(x(x'left downto x'left-split+1)) xor
        recursive_xor(x(x'left-split downto x'right));
    end if;
  end function recursive_xor;

  function bin2gray (bin : std_logic_vector) return std_logic_vector is
  begin
    return ('0' & bin(bin'left downto bin'right + 1)) xor bin;
  end bin2gray;

  function gray2bin (gray : std_logic_vector) return std_logic_vector is
    variable bin : std_logic_vector(gray'range) := (others => '0');
  begin
    -- this code will only work for descending vectors
    for i in gray'left downto gray'right loop
      if i = gray'left then
        bin(i) := gray(i);
      else
        bin(i) := recursive_xor(gray(gray'left downto i));
      end if;
    end loop;
    return bin;
  end gray2bin;
  
  procedure toggle (signal s : inout std_logic) is
  begin  -- toggle
    s <= not s;
  end toggle;

  procedure toggle (signal s : inout boolean) is
  begin  -- toggle
    s <= not s;
  end toggle;

 end macros;
