library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ycbcr_pack.all;


package ycbcr_pack4tb is
  
  ----------------------------------------------------------------------------
  -- !!!!!!! Parameters characterizing your design !!!!!!!
  -- FUNCTION OF THE TESTBENCH DEPENDS ON CORRECT INFORMATION ABOUT YOUR DESIGN
  ----------------------------------------------------------------------------
  constant serial_pixel_gap  : integer := 0;   -- set the gap between two consecutive pixels, e.g. 0 = one pixel is written to your design with every clock cycle  
  constant pipeline_depth    : integer := 1;   -- set the pipeline depth of your design

  -- possibly helpful parameter
  constant diff_gain  : real := 1.0;      -- factor amplifying the visual difference between the implemented design and the accurate floating point based transformation
  
  ----------------------------------------------------------------------------
  -- Constants, specific to the general project, should not be changed 
  ----------------------------------------------------------------------------
  constant clockcycle : time := 10.0 ns;    -- defines a clock frequency for the functional simulations
  
  ----------------------------------------------------------------------------
  -- Constants to control the testbench
  ----------------------------------------------------------------------------
  constant histogram_steps : integer := 1024;    -- granularity of the histograms that are plotted after the simulation
  constant max_avg_error   : real    := 6.0;     -- maximum average error of your design versus the reference
  
  ----------------------------------------------------------------------------
  -- Constants for file names (assuming that modelsim runs in ./tb/msim/)
  ----------------------------------------------------------------------------
  
  constant stimuli_picture_rgb : string := "../rgb_picture.txt";      -- values of the reference rgb picture (assume that the picture is in ./tb/
  constant diff_rgb_picture    : string := "../output/diff_grey.bmp"; -- possibly helpful image to display differences of your design versus the reference
  
  constant plot_histo_y  : string := "../output/histo_y.txt";
  constant plot_histo_cb : string := "../output/histo_cb.txt";
  constant plot_histo_cr : string := "../output/histo_cr.txt";
  
  ----------------------------------------------------------------------------
  -- Type definitions
  ----------------------------------------------------------------------------
  
  -- types used for the reference
  type rgb_pixel_real_t is
  record
    r  : real;
    g  : real;
    b  : real;
  end record;

  type ycbcr_pixel_real_t is
  record
    y  : real;
    cb : real;
    cr : real;
  end record;

  -- arrays containing pixels of image
  type image_rgb_array_t is array (natural range <> ) of rgb_pixel_t;
  type image_rgb_array_pointer_t is access image_rgb_array_t;
  type image_ycbcr_array_t is array (natural range <> ) of ycbcr_pixel_t;
  type image_ycbcr_array_pointer_t is access image_ycbcr_array_t;
  type image_ycbcr_real_array_t is array (natural range <> ) of ycbcr_pixel_real_t;
  type image_ycbcr_real_array_pointer_t is access image_ycbcr_real_array_t;
  type image_rgb_diff_array_t is array (natural range <> ) of rgb_pixel_real_t;
  type image_rgb_diff_array_pointer_t is access image_rgb_diff_array_t;

end ycbcr_pack4tb;


package body ycbcr_pack4tb is

end ycbcr_pack4tb;
