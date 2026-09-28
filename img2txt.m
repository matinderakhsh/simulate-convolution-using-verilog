% خواندن تصویر سیاه و سفید و ذخیره هر پیکسل در فایل متنی
clc; clear; close all;

% مسیر فایل تصویری
imagePath = 'Source2.jpg';  % مسیر تصویر خود را اینجا بگذارید

% خواندن تصویر
img = imread(imagePath);

% اگر رنگی بود، به سیاه و سفید تبدیل کن
if size(img,3) == 3
    img = rgb2gray(img);
end

% اطمینان از سایز 1080x1080
img = imresize(img, [750 750]);

% تبدیل تصویر به بردار ستونی (هر پیکسل یک مقدار)
pixels = reshape(img.', [], 1);



% نام فایل خروجی
outputFile = 'image_Input.txt';

% باز کردن فایل برای نوشتن
fid = fopen(outputFile, 'w');

% بررسی باز بودن فایل
if fid == -1
    error('فایل برای نوشتن باز نشد.');
end

% نوشتن هر مقدار پیکسل در یک خط
fprintf(fid, '%d\n', pixels);

% بستن فایل
fclose(fid);

disp('تمام پیکسل‌ها با موفقیت در فایل image_Input.txt ذخیره شدند.');
