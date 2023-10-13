library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

use work.syslog.all;
use work.macros.all;
use work.ycbcr_pack.all;
use work.ycbcr_pack4tb.all;


entity testbench is

end entity testbench;


architecture functional_test of testbench is

  component ycbcr_top is
    port (
      nrst        : in  std_logic;
      clk         : in  std_logic;
      pixel_in_p  : in  rgb_pixel_t;
      pixel_out_p : out ycbcr_pixel_t
    );
  end component ycbcr_top;

  signal clk          : std_logic := '0';
  signal nrst          : std_logic := '1';
  signal pixel_input  : rgb_pixel_t;
  signal pixel_output : ycbcr_pixel_t;
  -- shared variables for synchronising and information exchange between testbench processes
  shared variable x_width     : integer;
  shared variable y_width     : integer;
  shared variable pix_num     : integer;
  shared variable picture_rgb : image_rgb_array_pointer_t;

begin -- architecture
  ----------------------------------------------------------------------------
  -- clock and nrst generation
  ----------------------------------------------------------------------------
  clk  <= not clk  after clockcycle / 2;
  nrst <= '0', '1' after clockcycle * 4;

  -----------------------------------------------------------------------------
  -- Component instantiation
  -----------------------------------------------------------------------------
  ycbcr_transformator : ycbcr_top
  port map (
    nrst        => nrst,
    clk         => clk,
    pixel_in_p  => pixel_input,
    pixel_out_p => pixel_output
  );

  -----------------------------------------------------------------------------
  -- Stimuli for the designs
  -----------------------------------------------------------------------------
  stimuli : process
    file rgb_picture_file : text;
    variable status : file_open_status;
    variable l : line;
    variable s : integer;

  begin

    -- open file
    file_open(status, rgb_picture_file, stimuli_picture_rgb, read_mode);
    if status /= open_ok then
      syslog(error, "Could not open file: " & stimuli_picture_rgb);
      syslog_terminate;
    end if;

    -- read prepared rgb picture ----------------------------------------
    -- first, read image resolution
    readline(rgb_picture_file, l);
    read(l, s);
    x_width := s;
    readline(rgb_picture_file, l);
    read(l, s);
    y_width := s;
    -- total number of pixels
    pix_num := x_width * y_width;

    picture_rgb := new image_rgb_array_t(0 to pix_num-1);

    -- then, read the pixels themselves 
    for i in 0 to pix_num-1 loop
      readline(rgb_picture_file, l);
      read(l, s);
      picture_rgb(i).r := to_unsigned(s, rgb_color_depth);
      readline(rgb_picture_file, l);
      read(l, s);
      picture_rgb(i).g := to_unsigned(s, rgb_color_depth);
      readline(rgb_picture_file, l);
      read(l, s);
      picture_rgb(i).b := to_unsigned(s, rgb_color_depth);
    end loop;
    file_close(rgb_picture_file);
    -- end read prepared rgb picture ----------------------------------------

    pixel_input.r <= (others => '0');
    pixel_input.g <= (others => '0');
    pixel_input.b <= (others => '0');
    
    -- wait until reset is released
    wait until nrst = '0';
    wait until nrst = '1';

    -- transmit pixels to the design under test (DUT)
    for i in 0 to pix_num-1 loop
      pixel_input <= picture_rgb(i);
      wait for clockcycle * (serial_pixel_gap + 1);
    end loop;

    wait; -- for ever

  end process stimuli;

  -----------------------------------------------------------------------------
  -- Monitoring of the results
  -----------------------------------------------------------------------------
  monitor : process
    variable picture_ycbcr     : image_ycbcr_array_pointer_t;
    variable picture_ref_ycbcr : image_ycbcr_real_array_pointer_t;
    variable picture_rgb_diff  : image_rgb_diff_array_pointer_t;

    type characterFile_Typ is file of character;
    file diff_pic_f          : characterFile_Typ;
    file f_histo_y           : text;
    file f_histo_cb          : text;
    file f_histo_cr          : text;
    type histo_t is array (0 to histogram_steps-1) of integer;
    variable histo_design_y  : histo_t;
    variable histo_design_cb : histo_t;
    variable histo_design_cr : histo_t;
    variable histo_ref_y     : histo_t;
    variable histo_ref_cb    : histo_t;
    variable histo_ref_cr    : histo_t;
    variable histo_index     : integer;
    variable histo_step      : integer;
    variable status          : file_open_status;
    variable l               : line;
    variable s_design        : integer;
    variable s_ref           : integer;

    variable op_cycles       : integer := 0;
    variable avg_error       : real := 0.0;
    variable diff_tmp        : real := 0.0;

  begin

    -- wait until reset is released
    wait until nrst = '0';
    wait until nrst = '1';
    
    -- start of the transformation process
    op_cycles := time(now) / clockcycle;
    
    -- wait until first result exits the DUT
    wait for (pipeline_depth + 1) * clockcycle;
    
    -- receive ycbcr pixels from design under test (DUT)
    picture_ycbcr := new image_ycbcr_array_t(0 to pix_num-1);
    for i in 0 to pix_num-1 loop
      picture_ycbcr(i) := pixel_output;
      wait for clockcycle * (serial_pixel_gap + 1);
    end loop;
    
    -- calculate the number of cycles for the transformation process
    syslog_print("");
    syslog_print("Number of clock cycles for the transformation   N_cycles = " & image((time(now)/clockcycle) - op_cycles));
    
    -- compute the accurate reference ycbcr-transformation using the real data type
    picture_ref_ycbcr := new image_ycbcr_real_array_t(0 to pix_num-1);
    for i in 0 to pix_num-1 loop
      picture_ref_ycbcr(i).y  := 0.299*real(to_integer(picture_rgb(i).r))
                                 + 0.587*real(to_integer(picture_rgb(i).g))
                                 + 0.114*real(to_integer(picture_rgb(i).b));
      picture_ref_ycbcr(i).cb := -0.168736*real(to_integer(picture_rgb(i).r))
                                 + (-0.331264)*real(to_integer(picture_rgb(i).g))
                                 + 0.5*real(to_integer(picture_rgb(i).b))
                                 + real(2**(ycbcr_color_depth-1));
      picture_ref_ycbcr(i).cr := 0.5*real(to_integer(picture_rgb(i).r))
                                 + (-0.418688)*real(to_integer(picture_rgb(i).g))
                                 + (-0.081312)*real(to_integer(picture_rgb(i).b))
                                 + real(2**(ycbcr_color_depth-1));
    end loop;
    deallocate(picture_rgb);
    
    -- generate histograms for each channel
    file_open(status, f_histo_y, plot_histo_y, write_mode);
    if status /= open_ok then
      syslog(error, "Could not open file: " & plot_histo_y);
      syslog_terminate;
    end if;
    file_open(status, f_histo_cb, plot_histo_cb, write_mode);
    if status /= open_ok then
      syslog(error, "Could not open file: " & plot_histo_cb);
      syslog_terminate;
    end if;
    file_open(status, f_histo_cr, plot_histo_cr, write_mode);
    if status /= open_ok then
      syslog(error, "Could not open file: " & plot_histo_cr);
      syslog_terminate;
    end if;

    -- init the variables for the histograms
    for i in 0 to histogram_steps-1 loop
      histo_design_y(i)  := 0;
      histo_design_cb(i) := 0;
      histo_design_cr(i) := 0;
      histo_ref_y(i)     := 0;
      histo_ref_cb(i)    := 0;
      histo_ref_cr(i)    := 0;
    end loop;

    for i in 0 to pix_num-1 loop
      -- write the histogram for the design
      histo_index := to_integer(picture_ycbcr(i).y(ycbcr_color_depth-1 downto ycbcr_color_depth-log2_ceil(histogram_steps)));
      histo_design_y(histo_index) := histo_design_y(histo_index) + 1;
      histo_index := to_integer(picture_ycbcr(i).cb(ycbcr_color_depth-1 downto ycbcr_color_depth-log2_ceil(histogram_steps)));
      histo_design_cb(histo_index) := histo_design_cb(histo_index) + 1;
      histo_index := to_integer(picture_ycbcr(i).cr(ycbcr_color_depth-1 downto ycbcr_color_depth-log2_ceil(histogram_steps)));
      histo_design_cr(histo_index) := histo_design_cr(histo_index) + 1;
      
      -- write the histogram for the reference
      histo_index := to_integer(to_unsigned(integer(picture_ref_ycbcr(i).y), ycbcr_color_depth)(ycbcr_color_depth-1 downto ycbcr_color_depth-log2_ceil(histogram_steps)));
      histo_ref_y(histo_index) := histo_ref_y(histo_index) + 1;
      histo_index := to_integer(to_unsigned(integer(picture_ref_ycbcr(i).cb), ycbcr_color_depth)(ycbcr_color_depth-1 downto ycbcr_color_depth-log2_ceil(histogram_steps)));
      histo_ref_cb(histo_index) := histo_ref_cb(histo_index) + 1;
      histo_index := to_integer(to_unsigned(integer(picture_ref_ycbcr(i).cr), ycbcr_color_depth)(ycbcr_color_depth-1 downto ycbcr_color_depth-log2_ceil(histogram_steps)));
      histo_ref_cr(histo_index) := histo_ref_cr(histo_index) + 1;
    end loop;

    -- write all histograms of the diverse channels into the different files
    for i in 0 to histogram_steps-1  loop
      histo_step := (2**ycbcr_color_depth/histogram_steps)*i + 2**ycbcr_color_depth/histogram_steps/2;
      -- y channel
      s_design := histo_design_y(i);
      s_ref    := histo_ref_y(i);
      write(l, image(histo_step) & "  " & image(s_ref) & "  " & image(s_design));
      writeline(f_histo_y, l);
      -- cb channel
      s_design := histo_design_cb(i);
      s_ref    := histo_ref_cb(i);
      write(l, image(histo_step) & "  " & image(s_ref) & "  " & image(s_design));
      writeline(f_histo_cb, l);
      -- cr channel
      s_design := histo_design_cr(i);
      s_ref    := histo_ref_cr(i);
      write(l, image(histo_step) & "  " & image(s_ref) & "  " & image(s_design));
      writeline(f_histo_cr, l);
    end loop;
    file_close(f_histo_y);
    file_close(f_histo_cb);
    file_close(f_histo_cr);
  
    -- compute the average error of the design
    avg_error := 0.0;
    for i in 0 to pix_num-1 loop
      diff_tmp := real(to_integer(picture_ycbcr(i).y)) - picture_ref_ycbcr(i).y;
      avg_error := avg_error + 4.0 * abs(diff_tmp);
      diff_tmp := real(to_integer(picture_ycbcr(i).cb)) - picture_ref_ycbcr(i).cb;
      avg_error := avg_error + abs(diff_tmp);
      diff_tmp := real(to_integer(picture_ycbcr(i).cr)) - picture_ref_ycbcr(i).cr;
      avg_error := avg_error + abs(diff_tmp);
    end loop;
    avg_error := avg_error / real(pix_num) / 6.0;

    syslog_print("Average error of your design   E_avg = " & image(avg_error));
    if avg_error > max_avg_error then
      syslog(error, "The average error of your design exceeds the maximum permitted value of " & image(max_avg_error));
    end if;
  
    -- generate a picture based on the difference between reference and design
    -- it is a grey scale picture, therefore only y channel is needed
    picture_rgb_diff := new image_rgb_diff_array_t(0 to pix_num-1);
    for i in 0 to pix_num-1 loop
      picture_rgb_diff(i).r := 0.0 + abs(real(to_integer(picture_ycbcr(i).y)) - picture_ref_ycbcr(i).y) * diff_gain;
      picture_rgb_diff(i).g := picture_rgb_diff(i).r;
      picture_rgb_diff(i).b := picture_rgb_diff(i).r;

      -- pixel saturation needed to mask errors introduced by inaccuracies of the design
      if (picture_rgb_diff(i).r > 255.0) then
        picture_rgb_diff(i).r := 255.0;
      end if;
      if (picture_rgb_diff(i).r < 0.0) then
        picture_rgb_diff(i).r := 0.0;
      end if;
      if (picture_rgb_diff(i).g > 255.0) then
        picture_rgb_diff(i).g := 255.0;
      end if;
      if (picture_rgb_diff(i).g < 0.0) then
        picture_rgb_diff(i).g := 0.0;
      end if;
      if (picture_rgb_diff(i).b > 255.0) then
        picture_rgb_diff(i).b := 255.0;
      end if;
      if (picture_rgb_diff(i).b < 0.0) then
        picture_rgb_diff(i).b := 0.0;
      end if;
    end loop;

    -- open file
    file_open(status, diff_pic_f, diff_rgb_picture, write_mode);
    if status /= open_ok then
      syslog(error, "Could not open file: " & diff_rgb_picture);
      syslog_terminate;
    end if;

    -- write bmp header
    write(diff_pic_f, character'val(66));
    write(diff_pic_f, character'val(77));
    write(diff_pic_f, character'val(54));
    write(diff_pic_f, character'val(244));
    write(diff_pic_f, character'val(1));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(54));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(40));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(x_width mod 256));
    write(diff_pic_f, character'val((x_width / 256) mod 256));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(y_width mod 256));
    write(diff_pic_f, character'val((y_width / 256) mod 256));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(1));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(24));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(244));
    write(diff_pic_f, character'val(1));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));
    write(diff_pic_f, character'val(0));

    -- write pixels into bmp file
    for y in 0 to y_width-1 loop
      for x in 0 to x_width-1 loop
        write(diff_pic_f, character'val(integer(picture_rgb_diff(y*x_width + x).b)));
        write(diff_pic_f, character'val(integer(picture_rgb_diff(y*x_width + x).g)));
        write(diff_pic_f, character'val(integer(picture_rgb_diff(y*x_width + x).r)));
      end loop;
      -- zero padding if a row is not a multiple of 4
      if x_width*3 mod 4 /= 0 then
        for i in 0 to 3 - x_width*3 mod 4 loop
          write(diff_pic_f, character'val(0));
        end loop;
      end if;
    end loop;
    
    file_close(diff_pic_f);
    deallocate(picture_rgb_diff);
    -- end write rgb  picture
    
    deallocate(picture_ycbcr);
    deallocate(picture_ref_ycbcr);

    syslog_terminate;

  end process monitor;

end architecture functional_test;
