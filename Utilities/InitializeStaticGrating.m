function [opts] = InitializeStaticGrating(tiltInDegrees,cont_idx)
% Camden MacDowell 2021
% creates static gratings at angles in tileInDegress (vector)
% cont_idx is the contrast of the grating (def=1). 

if nargin <2
   cont_idx = ones(1,numel(tiltInDegrees)); 
end

% Get the screen numbers
AssertOpenGL;
Screen('Preference', 'SkipSyncTests', 1);
screens = Screen('Screens');

% Draw to the external screen if avaliable
opts.screenNumber = max(screens);

% Define black and white
black = BlackIndex(opts.screenNumber);
white = WhiteIndex(opts.screenNumber);
gray = white / 2; %camden you have checked, and this is equal to the average pixel value of each stimulus
absoluteDifferenceBetweenWhiteAndGray = abs(white - gray);

% Open an on screen retinoOpts.window
[opts.window, opts.windowRect] = Screen('OpenWindow', opts.screenNumber, gray);
[screenXpixels,screenYpixels] = Screen('windowSize', opts.window);

% If the grating is clipped on the sides, increase widthOfGrid.
widthOfGrid = screenXpixels*4; %make it much larger so that you can rotate and trim to size
halfWidthOfGrid = widthOfGrid / 2;
widthArray = (-halfWidthOfGrid) : halfWidthOfGrid;  % widthArray is used in creating the meshgrid.

opts.gratingtex = cell(1,numel(tiltInDegrees));
%create gratings
tiltInRadians = 0 * pi / 180; % The tilt of the grating in radians.
% To lengthen the period of the grating, increase pixelsPerPeriod.
pixelsPerPeriod = 150; % How many pixels will each period/cycle occupy?
spatialFrequency = 1 / pixelsPerPeriod; % How many periods/cycles are there in a pixel?
radiansPerPixel = spatialFrequency * (2 * pi); % = (periods per pixel) * (2 pi radians per period)

[x, y] = meshgrid(widthArray, widthArray);
a=cos(tiltInRadians)*radiansPerPixel;
b=sin(tiltInRadians)*radiansPerPixel;

% Converts meshgrid into a sinusoidal grating 
imageMatrix = sin(a*x+b*y);

for i = 1:numel(tiltInDegrees)
    %scale contrast since mageMatrix is a fraction between minus one and one
    imageMatrix_scaled=imageMatrix*cont_idx(i);
    
    %convert to grayscale
    grayscaleImageMatrix = gray + absoluteDifferenceBetweenWhiteAndGray * imageMatrix_scaled;    

    %crop to size of screen
    temp = imrotate(grayscaleImageMatrix,tiltInDegrees(i));
    cent = round(size(grayscaleImageMatrix,1)/2);
    temp = temp(round(cent-screenXpixels/2)+1:round(cent+screenXpixels/2),round(cent-screenYpixels/2)+1:round(cent+screenYpixels/2));
    %make top corner white
    temp(1:96,1:54)=255;
    opts.gratingtex{i}=Screen('MakeTexture', opts.window, temp,[],1);
end

% Perform initial Flip to sync us to the VBL and for getting an initial
% VBL-Timestamp for our "WaitBlanking" emulation:
opts.vbl=Screen('Flip', opts.window);


end









