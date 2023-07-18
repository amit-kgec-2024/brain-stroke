% Code to remove the outer bright skull from a CT cross sectional image.
clc;    % Clear the command window.
close all;  % Close all figures (except those of imtool.)
clear;  % Erase all existing variables. Or clearvars if you want.
workspace;  % Make sure the workspace panel is showing.
format long g;
format compact;
fontSize = 20;

% Get the name of the image the user wants to use.
% baseFileName = 'skull_stripping_demo_image.dcm';
baseFileName = ('skull_stripping_demo_image.png');
% Get the full filename, with path prepended.
folder = pwd;
fullFileName = fullfile(folder, baseFileName);

% Check if the file exists.
if ~exist(fullFileName, 'file')
	% The file doesn't exist -- didn't find it there in that folder.  
	% Check the entire search path (other folders) for the file by stripping off the folder.
	fullFileNameOnSearchPath = baseFileName; % No path this time.
	if ~exist(fullFileNameOnSearchPath, 'file')
		% Still didn't find it.  Alert user.
		errorMessage = sprintf('Error: %s does not exist in the search path folders.', fullFileName);
		uiwait(warndlg(errorMessage));
		return;
	end
end

% Read in a demo image.
% grayImage = dicomread(fullFileName);
grayImage = imread(fullFileName);
% Get the dimensions of the image.  
% numberOfColorBands should be = 1.
[rows, columns, numberOfColorChannels] = size(grayImage);
if numberOfColorChannels > 1
	% It's not really gray scale like we expected - it's color.
	% Convert it to gray scale by taking only the green channel.
	grayImage = grayImage(:, :, 2); % Take green channel.
end
% Display the image.
subplot(2, 3, 1);
imshow(grayImage, []);
axis on;
caption = sprintf('Original Grayscale Image\n%s', baseFileName);
title(caption, 'FontSize', fontSize, 'Interpreter', 'None');

drawnow;
hp = impixelinfo();
% Set up figure properties:
% Enlarge figure to full screen.
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
% Get rid of tool bar and pulldown menus that are along top of figure.
% set(gcf, 'Toolbar', 'none', 'Menu', 'none');
% Give a name to the title bar.
set(gcf, 'Name', 'Demo by ImageAnalyst', 'NumberTitle', 'Off') 

% Make the pixel info status line be at the top left of the figure.
hp.Units = 'Normalized';
hp.Position = [0.01, 0.97, 0.08, 0.05];

% Display the histogram so we can see what gray level we need to threshold it at.
subplot(2, 3, 2:3);
% For this image, there is a huge number of black pixels with gray level less than about 11,
% and that makes a huge spike at the first bin.  Ignore those pixels so we can get a histogram of just non-zero pixels.
% histObject = histogram(grayImage(grayImage >= 11))
[pixelCounts, grayLevels] = imhist(grayImage(grayImage >= 11), 65536);
lightblue = [9, 90, 40]/100; % Our custom color - a bluish color.
bar(grayLevels, pixelCounts, 'BarWidth', 1, 'FaceColor', lightblue);
% Find the last gray level and set up the x axis to be that range.
lastGL = find(pixelCounts>0, 1, 'last');
xlim([0, lastGL]);
grid on;
% Set up tick marks every 50 gray levels.
ax = gca;
ax.XTick = 0 : 100 : lastGL;
title('Histogram of Non-Black Pixels', 'FontSize', 15, 'Interpreter', 'None');
xlabel('Gray Level', 'FontSize', 15);
ylabel('Pixel Counts', 'FontSize', 15);

% Threshold the image to make a binary image.
thresholdValue = 260;
binaryImage = grayImage > thresholdValue;
% Display the image.
subplot(2, 3, 4);
imshow(binaryImage, []);
axis on;
caption = sprintf('Thresholded at %d Gray', thresholdValue);
title(caption, 'FontSize', 15, 'Interpreter', 'None');

% Extract the outer blob, which is the skull.  
% The outermost blob will have a label number of 1.
labeledImage = bwlabel(binaryImage);		% Assign label ID numbers to all blobs.
binaryImage = ismember(labeledImage, 1);	% Use ismember() to extract blob #1.
% Thicken it a little with imdilate().
binaryImage = imdilate(binaryImage, true(5));

% Mask out the skull from the original gray scale image.
skullFreeImage = grayImage; % Initialize
skullFreeImage(binaryImage) = 0; % Mask out.
% Display the image.
subplot(2, 3, 5);
imshow(skullFreeImage, []);
axis on;
caption = sprintf('Gray Scale Image\nwith Skull Stripped Away');
title(caption, 'FontSize', 15, 'Interpreter', 'None');

% Give user a chance to see the results on this figure, then offer to continue and find the Hammoreige.
promptMessage = sprintf('Do you want to continue and find the HEMEORRHAGE, THRESHOLDED, ALONE,\nor Quit?');
titleBarCaption = 'Continue?';
buttonText = questdlg(promptMessage, titleBarCaption, 'Continue', 'Quit', 'Continue');
if strcmpi(buttonText, 'Quit')
	return;
end

% Now threshold to find the Hemorrhage
thresholdValue = 270;
binaryImage = skullFreeImage > thresholdValue;
% Display the image.
hFig2 = figure();
subplot(2, 3, 1);
imshow(binaryImage, []);
axis on;
caption = sprintf('Initial Binary Image\nThresholded at %d Gray Levels', thresholdValue);
title(caption, 'FontSize', fontSize, 'Interpreter', 'None');

% Set up figure properties:
% Enlarge figure.
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.25 0.15 .5 0.7]);
% Get rid of tool bar and pulldown menus that are along top of figure.
% set(gcf, 'Toolbar', 'none', 'Menu', 'none');
% Give a name to the title bar.
set(gcf, 'Name', 'Demo by ImageAnalyst', 'NumberTitle', 'Off') 
drawnow;

% Assume the Hemorrhage is the largest blob, so extract it
binaryTumorImage = bwareafilt(binaryImage, 1);
% Display the image.
subplot(2, 3, 2);
imshow(binaryTumorImage, []);
axis on;
caption = sprintf('Brainstroke Alone');
title(caption, 'FontSize', 15, 'Interpreter', 'None');

drawnow;
hp = impixelinfo();
% Set up figure properties:
% Enlarge figure to full screen.
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
% Get rid of tool bar and pulldown menus that are along top of figure.
% set(gcf, 'Toolbar', 'none', 'Menu', 'none');
% Give a name to the title bar.
set(gcf, 'Name', 'Demo by ImageAnalyst', 'NumberTitle', 'Off') 

% Make the pixel info status line be at the top left of the figure.
hp.Units = 'Normalized';
hp.Position = [0.01, 0.97, 0.08, 0.05];

% Find hemorrhage boundaries.
% bwboundaries() returns a cell array, where each cell contains the row/column coordinates for an object in the image.
% Plot the borders of the Hemorrhage over the original grayscale image using the coordinates returned by bwboundaries.
subplot(2, 3, 3);
imshow(grayImage, []);
axis on;
caption = sprintf('hemorrhage\nOutlined in red in the overlay'); 
title(caption, 'FontSize', 15, 'Interpreter', 'None'); 
axis image; % Make sure image is not artificially stretched because of screen's aspect ratio.
hold on;
boundaries = bwboundaries(binaryTumorImage);
numberOfBoundaries = size(boundaries, 1);
for k = 1 : numberOfBoundaries
	thisBoundary = boundaries{k};
	% Note: since array is row, column not x,y to get the x you need to use the second column of thisBoundary.
	plot(thisBoundary(:,2), thisBoundary(:,1), 'r', 'LineWidth', 2);
end
hold off;

% Give user a chance to see the results on this figure, then offer to continue and find the Hammoreige.
promptMessage = sprintf('Do you want to continue and find the SKULL MRI, Histogram of Skull, Image HistoEqualized, Hisotogram of Image HistoEqualized,\nor Quit?');
titleBarCaption = 'Continue?';
buttonText = questdlg(promptMessage, titleBarCaption, 'Continue', 'Quit', 'Continue');
if strcmpi(buttonText, 'Quit')
	return;
end

url = dicomread('CT01163NO.dcm');
URL=im2double(url);
IG=mat2gray(URL);
figure;
subplot(2, 3, 1);
imshow(IG,[]);

axis on;
caption = sprintf('Skull MRI');
title(caption, 'FontSize', 15, 'Interpreter', 'None');
subplot(2, 3, 2:3);

histogram(IG);
lastGL = 0.9;  % Last gray level for x-axis range
xlim([0, lastGL]);
grid on;
% Set up tick marks every 50 gray levels.
ax = gca;
xlabel('Gray Level', 'FontSize', 15);
ylabel('Pixel Counts', 'FontSize', 15);
title('Histogram of Skull', 'FontSize', 15, 'Interpreter', 'None');
drawnow;
hp = impixelinfo();
% Set up figure properties:
% Enlarge figure to full screen.
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
% Get rid of tool bar and pulldown menus that are along top of figure.
% set(gcf, 'Toolbar', 'none', 'Menu', 'none');
% Give a name to the title bar.
set(gcf, 'Name', 'Demo by ImageAnalyst', 'NumberTitle', 'Off') 

% Make the pixel info status line be at the top left of the figure.
hp.Units = 'Normalized';
hp.Position = [0.01, 0.97, 0.08, 0.05];
HistEquImg=histeq(IG);
subplot(2, 3, 4);imshow(HistEquImg,[]);
axis on;
caption = sprintf('Image HistoEqualized');
title(caption, 'FontSize', 15, 'Interpreter', 'None');
subplot(2, 3, 5:6);
histogram(HistEquImg);
lastGL = 0.9;  % Last gray level for x-axis range
xlim([0, lastGL]);
grid on;
% Set up tick marks every 50 gray levels.
ax = gca;
xlabel('Gray Level', 'FontSize', 15);
ylabel('Pixel Counts', 'FontSize', 15);
title('Hisotogram of Image HistoEqualized', 'FontSize', 15, 'Interpreter', 'None');

% Give user a chance to see the results on this figure, then offer to continue and find the Hammoreige.
promptMessage = sprintf('Do you want to continue and find the Gradient magnitude (gradmag), Histogram of Gradient Magnitude, Histogram of Opening-closing by reconstruction, Watershed superimposed on IG,\nor Quit?');
titleBarCaption = 'Continue?';
buttonText = questdlg(promptMessage, titleBarCaption, 'Continue', 'Quit', 'Continue');
if strcmpi(buttonText, 'Quit')
	return;
end

%bw1 =  HistEquImg>graythresh(HistEquImg);
level1=graythresh(HistEquImg);
bw1=im2bw(HistEquImg,level1);
%figure,subplot(2,3,1);imshow(bw1,[]);title('HistEquImg Thresholded Image');
hy = fspecial('sobel');
hx = hy';
Iy = imfilter(double(HistEquImg), hy, 'replicate');
Ix = imfilter(double(HistEquImg), hx, 'replicate');
gradmag = sqrt(Ix.^2 + Iy.^2);
figure;
subplot(2,3,1);imshow(gradmag,[]),
axis on;
caption = sprintf('Gradient magnitude (gradmag)');
title(caption, 'FontSize', 15, 'Interpreter', 'None');
subplot(2,3,2:3);
histogram(gradmag);
lastGL = 0.9;  % Last gray level for x-axis range
xlim([0, lastGL]);
grid on;
% Set up tick marks every 50 gray levels.
ax = gca;
xlabel('Gray Level', 'FontSize', 15);
ylabel('Pixel Counts', 'FontSize', 15);
title('Histogram of Gradient Magnitude', 'FontSize', 15, 'Interpreter', 'None');

L = watershed(gradmag);
% imgReconComp=imcomplement(imgRecon);
Se=strel('disk',3);
imgEroded=imerode(HistEquImg,Se);
imgRecon=imreconstruct(imgEroded,HistEquImg);
Iobr=imgRecon;
Iobrd = imdilate(Iobr,Se);
Iobrcbr = imreconstruct(imcomplement(Iobrd), imcomplement(Iobr));
Iobrcbr = imcomplement(Iobrcbr);
subplot(2,3,4);imshow(Iobrcbr,[]), 
axis on;
caption = sprintf('Opening-closing by reconstruction');
title(caption, 'FontSize', 15, 'Interpreter', 'None');
subplot(2,3,5);
histogram(Iobrcbr);
lastGL = 0.9;  % Last gray level for x-axis range
xlim([0, lastGL]);
grid on;
% Set up tick marks every 50 gray levels.
ax = gca;
xlabel('Gray Level', 'FontSize', 15);
ylabel('Pixel Counts', 'FontSize', 15);
title('Histogram of Opening-closing by reconstruction', 'FontSize', 13, 'Interpreter', 'None');

drawnow;
hp = impixelinfo();
% Set up figure properties:
% Enlarge figure to full screen.
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
% Get rid of tool bar and pulldown menus that are along top of figure.
% set(gcf, 'Toolbar', 'none', 'Menu', 'none');
% Give a name to the title bar.
set(gcf, 'Name', 'Demo by ImageAnalyst', 'NumberTitle', 'Off') 

% Make the pixel info status line be at the top left of the figure.
hp.Units = 'Normalized';
hp.Position = [0.01, 0.97, 0.08, 0.05];


subplot(2,3,6);imshow(HistEquImg,[]);
axis on;
caption = sprintf('Watershed superimposed on IG');
title(caption, 'FontSize', 15, 'Interpreter', 'None');
