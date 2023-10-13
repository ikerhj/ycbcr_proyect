%#ok<*UNRCH>
clear_workspace = 0;

generate_output_txt_img_file = 0;
generate_output_vhdl_snippet_file = 0;
generate_output_mif_file = 1;

%% define some constants and read image file to workspace
% imagefile = 'c5g_1440x1080.png';
% imagefile = 'c5g_1920x1440.png';
% imagefile = 'c5g_640x480.png';
imagefile = 'c5g_320x240.png';

output_txt_img_file = '../../tb/rgb_picture.txt';
output_vhdl_snippet_file = 'vhdl_snippet.txt';
output_mif_file = '../../rtl/testimg/testimg.mif';

raw_per_color_depth = 8;
rgb_per_color_depth = 16;
vhdl_rgb_color_depth = 6; % maximum value: 8
vhdl_file_with_color_id = 0;

rgb_picture_raw = imread(imagefile);
rgb_picture = double(rgb_picture_raw)/2^raw_per_color_depth;

%% transform to txt_picture which is readable for testbench
txt_rgb_picture_vals = floor(rgb_picture*2^rgb_per_color_depth);

[x_width,y_width] = size(txt_rgb_picture_vals(:,:,1));

txt_picture = [x_width; ...
               y_width; ...
               zeros(3*x_width*y_width,1)];

idx = 0;
for xdx = 1: x_width
  for ydx = 1:y_width
    idx = idx+1;
    txt_picture(3*idx:3*idx+2) = [txt_rgb_picture_vals(xdx,ydx,1); ...
                                  txt_rgb_picture_vals(xdx,ydx,2); ...
                                  txt_rgb_picture_vals(xdx,ydx,3)];
  end
end

%% Write data into file
if generate_output_txt_img_file
  fid1 = fopen(output_txt_img_file,'wt'); % create file
  for idx = 1:length(txt_picture)
    fprintf(fid1,'%d\n',txt_picture(idx));
  end
  fclose(fid1); % close file
end


%% some calculation for VHDL snippet and/or MIF
  
xlim = ceil(log2(x_width));
ylim = ceil(log2(y_width));

shift = 2^vhdl_rgb_color_depth;
vhdl_rgb_picture_vals = floor(rgb_picture*shift);
    
vhdl_rgb_picture_vals_single = vhdl_rgb_picture_vals(:,:,1)*shift^2 + ...
                               vhdl_rgb_picture_vals(:,:,2)*shift   + ...
                               vhdl_rgb_picture_vals(:,:,3);
vhdl_rgb_picture_vals_unique = unique(vhdl_rgb_picture_vals_single);
vhdl_rgb_picture_redvals_unique = floor(vhdl_rgb_picture_vals_single/shift^2);
vhdl_rgb_picture_grvals_unique = floor((vhdl_rgb_picture_vals_single - vhdl_rgb_picture_redvals_unique*shift^2)/shift);
vhdl_rgb_picture_blvals_unique = vhdl_rgb_picture_vals_single - vhdl_rgb_picture_grvals_unique*shift - vhdl_rgb_picture_redvals_unique*shift^2;

map_width = length(vhdl_rgb_picture_vals_unique);

vhdl_rgb_picture_map = zeros(x_width,y_width);
for xdx = 1:x_width
  for ydx = 1:y_width
    vhdl_rgb_picture_map(xdx,ydx) = find(vhdl_rgb_picture_vals_unique==vhdl_rgb_picture_vals_single(xdx,ydx));
  end
end
  
  
    idlim = ceil(log2(map_width));


%% Output VHDL code snippet
if generate_output_vhdl_snippet_file
  fid2 = fopen(output_vhdl_snippet_file,'wt');

  if vhdl_file_with_color_id

  
    fprintf(fid2,'\n');
    fprintf(fid2,['  signal addr_L : std_logic_vector(' int2str(xlim+ylim-1) ' downto 0);\n']);
    fprintf(fid2, '  signal valid_L : std_logic_vector(2 downto 0);\n');
    fprintf(fid2,['  signal color_id_L : std_logic_vector(' int2str(idlim-1) ' downto 0);\n']);
    fprintf(fid2,['  signal pixel_val_L : std_logic_vector(' int2str(3*vhdl_rgb_color_depth-1) ' downto 0);\n\n']);
  
    fprintf(fid2,'  case addr_L is\n');
    for xdx = 0:x_width-1
      for ydx = 0:y_width-1
        fprintf(fid2,'    when ');
        if xlim > 8 
          fprintf(fid2,['\"' byte2bitstr(floor(xdx/256),xlim-8) byte2bitstr(xdx-256*floor(xdx/256))]);
        else
          fprintf(fid2,['\"' byte2bitstr(xdx,xlim)]);
        end
        if ylim > 8 
          fprintf(fid2,[byte2bitstr(floor(ydx/256),ylim-8) byte2bitstr(ydx-256*floor(ydx/256)) '\"']);
        else
          fprintf(fid2,[byte2bitstr(ydx,ylim) '\"']);
        end
        fprintf(fid2,' => color_id_L <= ');
        if idlim > 16
          map_16 = floor(vhdl_rgb_picture_map(xdx+1,ydx+1)/256^2);
          map_8  = floor((vhdl_rgb_picture_map(xdx+1,ydx+1) - 256^2*map_16)/256);
          map_0  = vhdl_rgb_picture_map(xdx+1,ydx+1) - map_8*256 - map_16*256^2;
          fprintf(fid2,['\"' byte2bitstr(map_16,idlim-16) ...
                             byte2bitstr(map_8) ...
                             byte2bitstr(map_0) ...
                        '\";\n']);
        elseif idlim > 8
          map_8 = floor(vhdl_rgb_picture_map(xdx+1,ydx+1)/256);
          map_0  = vhdl_rgb_picture_map(xdx+1,ydx+1) - map_8*256;
          fprintf(fid2,['\"' byte2bitstr(map_8,idlim-8) ...
                             byte2bitstr(map_0) ...
                        '\";\n']);
        else
          map_0 = vhdl_rgb_picture_map(xdx+1,ydx+1);
          fprintf(fid2,['\"' byte2bitstr(map_0,idlim) '\";\n']);
        end
      end
    end
    fprintf(fid2,'    when others => color_id_L <= (others => ''0'');\n');
    fprintf(fid2,'  end case;\n\n');
  
    fprintf(fid2,'  case color_id_L is\n');
    for idx = 0:map_width-1
      fprintf(fid2,'    when ');
      if idlim > 16
        idx_16 = floor(idx/256^2);
        idx_8  = floor((idx - 256^2*idx_16)/256);
        idx_0  = idx - idx_8*256 - idx_16*256^2;
        fprintf(fid2,['\"' byte2bitstr(idx_16,idlim-16) ...
                           byte2bitstr(idx_8) ...
                           byte2bitstr(idx_0) ...
                      '\"']);
      elseif idlim > 8
        idx_8  = floor(idx/256);
        idx_0  = idx - idx_8*256;
        fprintf(fid2,['\"' byte2bitstr(idx_8,idlim-8) ...
                           byte2bitstr(idx_0) ...
                      '\"']);
      else
        idx_0 = idx;
        fprintf(fid2,['\"' byte2bitstr(idx_0,idlim) '\"']);
      end
      fprintf(fid2,[' => pixel_val_L <= ' ...
                    '\"' byte2bitstr(vhdl_rgb_picture_redvals_unique(idx+1),vhdl_rgb_color_depth) '\" & ' ... red
                    '\"' byte2bitstr(vhdl_rgb_picture_grvals_unique(idx+1) ,vhdl_rgb_color_depth) '\" & ' ... green
                    '\"' byte2bitstr(vhdl_rgb_picture_blvals_unique(idx+1) ,vhdl_rgb_color_depth) '\";\n' ... blue
                   ]);
    end
    fprintf(fid2,'    when others => pixel_val_L <= (others => ''0'');\n');
    fprintf(fid2,'  end case;\n\n');
  else
    fprintf(fid2,'\n');
    fprintf(fid2,['  signal addr_L : std_logic_vector(' int2str(xlim+ylim-1) ' downto 0);\n']);
    fprintf(fid2, '  signal valid_L : std_logic_vector(1 downto 0);\n');
    fprintf(fid2,['  signal pixel_val_L : std_logic_vector(' int2str(3*vhdl_rgb_color_depth-1) ' downto 0);\n\n']);
  
    fprintf(fid2,'  case addr_L is\n');
    for xdx = 0:x_width-1
      for ydx = 0:y_width-1
        fprintf(fid2,'    when ');
        if xlim > 8 
          fprintf(fid2,['\"' byte2bitstr(floor(xdx/256),xlim-8) byte2bitstr(xdx-256*floor(xdx/256))]);
        else
          fprintf(fid2,['\"' byte2bitstr(xdx,xlim)]);
        end
        if ylim > 8 
          fprintf(fid2,[byte2bitstr(floor(ydx/256),ylim-8) byte2bitstr(ydx-256*floor(ydx/256)) '\"']);
        else
          fprintf(fid2,[byte2bitstr(ydx,ylim) '\"']);
        end
        fprintf(fid2,[' => pixel_val_L <= ' ...
                      '\"' byte2bitstr(vhdl_rgb_picture_vals(xdx+1,ydx+1,1),vhdl_rgb_color_depth) '\" & ' ... red
                      '\"' byte2bitstr(vhdl_rgb_picture_vals(xdx+1,ydx+1,2),vhdl_rgb_color_depth) '\" & ' ... green
                      '\"' byte2bitstr(vhdl_rgb_picture_vals(xdx+1,ydx+1,3),vhdl_rgb_color_depth) '\";\n' ... blue
                     ]);
      end
    end
    fprintf(fid2,'    when others => pixel_val_L <= (others => ''0'');\n');
    fprintf(fid2,'  end case;\n\n');
  end

  fprintf(fid2,['  addr_L <= to_unsigned_std_logic_vector(xpos,' int2str(xlim) ') & to_unsigned_std_logic_vector(ypos,' int2str(ylim) ');\n']);
  fprintf(fid2, '  valid_L(1) <= valid_L(0);\n');
  fprintf(fid2,['  valid_L(0) <= xpos < ' int2str(x_width) ' and ypos < ' int2str(y_width) ';']);
  fprintf(fid2,'\n');

  fclose(fid2);
end


%% generate MIF
if generate_output_mif_file
  fid3 = fopen(output_mif_file,'wt');

  fprintf(fid3,'WIDTH = %d;\n',3*vhdl_rgb_color_depth);
%   fprintf(fid3,'DEPTH = %d;\n\n',x_width*y_width);
  fprintf(fid3,'DEPTH = %d;\n\n',y_width*2^xlim);
  fprintf(fid3,'ADDRESS_RADIX = HEX;\n');
  fprintf(fid3,'DATA_RADIX = HEX;\n\n');

  fprintf(fid3,'CONTENT BEGIN;\n');
  for ydx = 0:y_width-1
    for xdx = 0:x_width-1
      fprintf(fid3,'%s:%s;\n',dec2hex(ydx*2^xlim+xdx),dec2hex(vhdl_rgb_picture_vals_single(xdx+1,ydx+1)));
    end
  end
  fprintf(fid3,'END;');

  fclose(fid3);
end


%% end script
if clear_workspace
  clear all
end