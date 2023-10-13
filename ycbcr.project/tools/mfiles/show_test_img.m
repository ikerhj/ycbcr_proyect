
input_file = '../../tb/rgb_picture.txt';

rgb_color_depth = 16;

txt_picture = readmatrix(input_file);

x_width = txt_picture(1);
y_width = txt_picture(2);

img = zeros(x_width,y_width,3);
img(:,:,1) = reshape(txt_picture(3:3:end),[y_width,x_width]).';
img(:,:,2) = reshape(txt_picture(4:3:end),[y_width,x_width]).';
img(:,:,3) = reshape(txt_picture(5:3:end),[y_width,x_width]).';

imshow(img/2^rgb_color_depth)
