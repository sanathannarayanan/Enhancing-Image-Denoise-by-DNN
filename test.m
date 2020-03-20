%A = imread('pb.jpg')
gray = rgb2gray(car);
n = imnoise(gray,'gaussian');
net = denoisingNetwork('DnCNN');
f = denoiseImage(n,net);
b1 = imgaussfilt(n,0.8);
b = imsharpen(n,'Radius',2,'Amount',1);
f2 = denoiseImage(b,net);
f3 = denoiseImage(b1,net);
imshow(f2)
%f-f2;
imshow(b)
imshow(n)
imshow(f)
f4 = imsharpen(f,'Radius',2,'Amount',1);