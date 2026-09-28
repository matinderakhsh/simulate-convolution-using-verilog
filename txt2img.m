% text_to_image.m
% Ring_Source.txt: هر خط یک عدد 0..255 (به تعداد W*H)

W = 750;
H = 750;

x = dlmread('image_Output.txt');   % خواندن همه اعداد (ستونی)
x = x(:);

if numel(x) < W*H
    error('Not enough samples in file: need %d, got %d', W*H, numel(x));
end

x = x(1:W*H);                     % فقط به اندازه تصویر
img = reshape(x, [W, H])';        % تبدیل به ماتریس HxW (ترانهاده برای ردیف/ستون درست)
img = uint8(img);

imshow(img, []);
title('Image from text file');
imwrite(img, 'input_image.png');