-------------------------------------------------------------------------------
-- File       : syslog.vhd
-- Created    : 2003-06-27
-- Description: 
--
-- This package can be used to print out messages, generate statistics to
-- keep track on success or failure and handle expected errors and warnings.
-- 
-- The following message types are supported:
--    - NOTE        : should be used to give some USEFULL INFORMATION,
--                    e.g. "Testcase XY is starting ..."
--    - WARNING     : should be used when things happen which MAY RESULT in
--                    ERRORS, e.g. "Hold time violation"
--    - ERROR       : should be used when something DOES NOT WORK,
--                    e.g. "Incorrect XY Value"
--    - FATAL error : should be used when an UNRECOVERABLE ERROR occured,
--                    e.g. "Arbiter is not responding after 100 cycles"
--                    simulation will be TERMINATED
--    - DEBUG       : print out some debug information to help the author of
--                    the code, can be turned on and off
--
-- To keep track of the number of notes, warnings and errors the global
-- or a local syslog can be used. For the latter a local variable of
-- syslog_type has to be declared and used in the syslog procedures.
-- e.g.       variable log : syslog_type := SYSLOG_INIT;
-- The initialization with SYSLOG_INIT is important to ensure the proper
-- work of the tracking.
--
-- To handle expected errors and warnings the number of expected errors and
-- warnings can be set. This is usefull for error injection
-- e.g.       syslog_expect(error, "Injecting two errors ...", 2);
--            inject_some_errors(...);
--            syslog_expect(error, "Error injection done", 0);
--
-- Report and terminate procedures are provided to give a detailed report of
-- the number of errors, warnings and notes and to terminate the simulation.
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use std.textio.all;

package syslog is

  -- Syslog message levels
  type syslog_level is (debug, note, warning, error, fatal);
  -- counter for all messages and expected errors/warnings
  type syslog_level_count is array (syslog_level'left to syslog_level'right) of integer;
  -- turn on/off each message level
  type syslog_msgon is array (syslog_level'left to syslog_level'right) of boolean;

  type syslog_type is
    record
      msgon    : syslog_msgon;
      count    : syslog_level_count;
      expect   : syslog_level_count;
      testcase : integer;               -- number of current testcase
    end record;

  -- initialization value, has to be used when using a local syslog variable
  constant SYSLOG_INIT : syslog_type := (
    msgon    => (others => true),
    count    => (others => 0),
    expect   => (others => 0),
    testcase => 0);

  -- global syslog procedures
  -- turn messages on and off
  procedure syslog_on (level : in syslog_level; msgon : in boolean);
  procedure syslog_on (level : in syslog_level);
  procedure syslog_off (level : in syslog_level);
  -- print a mesage at level
  procedure syslog(level : in syslog_level; msg : in string);
  -- expect at level
  procedure syslog_expect (level : in syslog_level; n : in integer; msg : in string);
  -- give a report (number of errors, warnings and notes)
  procedure syslog_report;
  -- give a testcase notification and set testcase number
  procedure syslog_testcase (tc : integer; msg   : in string);
  -- give a testcase notification and increment testcase number
  procedure syslog_testcase (msg   : in string);
  -- give a report and terminate simulation
  procedure syslog_terminate;

  -- local syslog functions
  procedure syslog_on (syslog : inout syslog_type; level : in syslog_level; msgon : in boolean);
  procedure syslog_on (syslog : inout syslog_type; level : in syslog_level);
  procedure syslog_off (syslog : inout syslog_type; level : in syslog_level);
  procedure syslog(syslog            : inout syslog_type; level : in syslog_level; msg : in string);
  procedure syslog_expect (syslog    : inout syslog_type; level : in syslog_level; n : in integer; msg : in string);
  procedure syslog_report (syslog    : in    syslog_type);
  procedure syslog_testcase (syslog  : inout syslog_type; tc : integer; msg : in string);
  procedure syslog_testcase (syslog  : inout syslog_type; msg : in string);
  procedure syslog_terminate(syslog  : in    syslog_type);

  -- write a string to stdout
  procedure syslog_print(s : string);

  -- return string representations of the function parameters
  -- e.g. syslog(debug, "a = " & image(a); with a : std_logic_vector
  function image (i : time) return string;
  function image (i : integer) return string;
  function image (i : real) return string;
  function image (i : boolean) return string;
  function image (i : bit) return string;
  function image (i : bit_vector) return string;
  function image (i : std_logic) return string;
  function image (i : std_logic_vector) return string;
  function image (i : signed) return string;
  function image (i : unsigned) return string;
  -- return hexadecimal strings
  function heximage (i : bit_vector) return string;
  function heximage (i : std_logic_vector) return string;
  function heximage (i : signed) return string;
  function heximage (i : unsigned) return string;

end syslog;

package body syslog is

  -- write a string to stdout
  procedure syslog_print(s : string) is
    variable L : line;
  begin
    L := new string'(s);
    writeline(output, L);
    deallocate(L);
  end;
  ----------------------------------------------------------------------------
  -- Syslog procedures
  ----------------------------------------------------------------------------
  -- local syslog procedures
  procedure syslog_on (syslog : inout syslog_type; level : in syslog_level; msgon : in boolean) is
  begin
    syslog.msgon(level):= msgon;
  end syslog_on;

  procedure syslog_on (syslog : inout syslog_type; level : in syslog_level) is
  begin
    syslog.msgon(level):= true;
  end syslog_on;

  procedure syslog_off (syslog : inout syslog_type; level : in syslog_level) is
  begin
    syslog.msgon(level):= false;
  end syslog_off;

  procedure syslog(syslog : inout syslog_type; level : in syslog_level; msg : in string) is
    variable l : line;
  begin
    case level is
      when debug =>
        write(l, string'("DEBUG"));
        syslog.count(level) := syslog.count(level) + 1;
        
      when note =>
        write(l, string'("NOTE"));
        syslog.count(level) := syslog.count(level) + 1;
        
      when warning =>
        if syslog.expect(warning) > 0 then
          write(l, string'(" expected warning"));
          syslog.expect(level) := syslog.expect(level) - 1;
        else
          write(l, string'("WARNING"));
          syslog.count(level) := syslog.count(level) + 1;
        end if;
        
      when error =>
        if syslog.expect(error) > 0 then
          write(l, string'(" expected error"));
          syslog.expect(level) := syslog.expect(level) - 1;
        else
          write(l, string'("ERROR"));
          syslog.count(level) := syslog.count(level) + 1;
        end if;
        
      when fatal =>
        write(l, string'("FATAL"));
        syslog.count(level) := syslog.count(level) + 1;
        
      when others =>
        null;
    end case;
    write(l, ": " & image(now) & ": " & msg);
    if syslog.msgon(level) then
      writeline(output, l);
    end if;
    if level = fatal then
      assert false report "Simulation terminated due to fatal error"
        severity failure;
    end if;
  end syslog;

  procedure syslog_expect (syslog : inout syslog_type; level : in syslog_level; n : in integer; msg : in string) is
    variable l : line;
  begin
    if syslog.expect(level) > 0 then
      write(l, "ERROR: " & image(now) & ": missed expected ");
      case level is
        when error =>
          write(l, string'("errors"));
        when warning =>
          write(l, string'("warnings"));
        when others =>
          null;
      end case;
      if syslog.msgon(error) then
        writeline(output, l);
      end if;
    end if;
    write(l, "EXPECT " & image(n) & " ");
    case level is
      when error =>
        write(l, string'("errors"));
      when warning =>
        write(l, string'("warnings"));
      when others =>
        null;
    end case;
    write(l, ": " & msg);
    writeline(output, l);
    syslog.expect(level) := n;
  end syslog_expect;

  procedure syslog_report (syslog : in syslog_type) is
  begin
    syslog_print("SUMMARY: " & image(syslog.count(error)) & " error(s), " &
                 image(syslog.count(warning)) & " warning(s) and " &
                 image(syslog.count(note)) & " note(s)");
  end syslog_report;

  procedure syslog_testcase (syslog : inout syslog_type; tc : integer; msg : in string) is
  begin
    syslog_print(lf & "TESTCASE " & image(tc) & ": " &
                 image(now) & ": " & msg);
    syslog.testcase := tc;
  end syslog_testcase;

  procedure syslog_testcase (syslog : inout syslog_type; msg : in string) is
  begin
    syslog.testcase := syslog.testcase + 1;
    syslog_testcase(syslog, syslog.testcase, msg);
  end syslog_testcase;

  procedure syslog_terminate(syslog : in syslog_type) is
  begin
    if syslog.count(error) > 0 then
      syslog_print(lf & "TEST COMPLETED WITH ERRORS: " & image(now));
    else
      if syslog.count(warning) > 0 then
        syslog_print(lf & "TEST COMPLETED WITH WARNINGS: " & image(now));
      else
        syslog_print(lf & "TEST COMPLETED OK: " & image(now));
      end if;
    end if;
    syslog_report(syslog);
    assert false report "Simulation terminated normally"
      severity failure;
  end syslog_terminate;

  -- global syslog variable
  shared variable syslog_global : syslog_type := SYSLOG_INIT;

  -- global syslog procedures
  procedure syslog_on (level : in syslog_level; msgon : in boolean) is
  begin
    syslog_on(syslog_global, level, msgon);
  end syslog_on;

  procedure syslog_on (level : in syslog_level) is
  begin
    syslog_on(syslog_global, level);
  end syslog_on;

  procedure syslog_off (level : in syslog_level) is
  begin
    syslog_off(syslog_global, level);
  end syslog_off;

  procedure syslog(level : syslog_level; msg : in string) is
  begin
    syslog(syslog_global, level, msg);
  end syslog;

  procedure syslog_expect (level : syslog_level; n : in integer; msg : in string) is
  begin
    syslog_expect(syslog_global, level, n, msg);
  end syslog_expect;

  procedure syslog_report is
  begin
    syslog_report(syslog_global);
  end syslog_report;

  procedure syslog_testcase (tc : integer; msg : in string) is
  begin
    syslog_testcase(syslog_global, tc, msg);
  end syslog_testcase;

  procedure syslog_testcase (msg : in string) is
  begin
    syslog_testcase(syslog_global, msg);
  end syslog_testcase;

  procedure syslog_terminate is
  begin
    syslog_terminate(syslog_global);
  end syslog_terminate;

  function image (i : time) return string is
  begin
    return time'image(i);
  end image;

  function image (i : integer) return string is
  begin
    return integer'image(i);
  end image;

  function image (i : real) return string is
  begin
    return real'image(i);
  end image;

  function image (i : boolean) return string is
  begin
    return boolean'image(i);
  end image;
  
  function image (i : bit) return string is
  begin
    return bit'image(i);
  end image;

  function image (i : bit_vector) return string is
    variable l : line;
  begin
    write(l, i);
    return l.all;
  end image;
  
  function image (i : std_logic) return string is
  begin
    return std_logic'image(i);
  end image;
    
  function image (i : std_logic_vector) return string is
    variable l : line;
  begin
    write(l, i);
    return l.all;
  end image;
  
  function image (i : signed) return string is
    variable l : line;
  begin
    write(l, std_logic_vector(i));
    return l.all;
  end image;
  
  function image (i : unsigned) return string is
    variable l : line;
  begin
    write(l, std_logic_vector(i));
    return l.all;
  end image;
  
  function heximage (i : bit_vector) return string is
    variable slv : std_logic_vector(i'range);
    variable l : line;
  begin
    -- convert to std_logic_vector to make live easier
    for k in i'range loop
      if i(k) = '0' then
        slv(k) := '0';
      else
        slv(k) := '1';
      end if;
    end loop;  -- k
    -- write the std_logic_vector
    hwrite(l, std_logic_vector(slv));
    return l.all;
  end heximage;
  
  function heximage (i : std_logic_vector) return string is
    variable l : line;
  begin
    hwrite(l, std_logic_vector(i));
    return l.all;
  end heximage;
  
  function heximage (i : signed) return string is
    variable l : line;
  begin
    hwrite(l, std_logic_vector(i));
    return l.all;
  end heximage;
  
  function heximage (i : unsigned) return string is
    variable l : line;
  begin
    hwrite(l, std_logic_vector(i));
    return l.all;
  end heximage;

end syslog;
