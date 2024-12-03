function [opts] = InitializeDriftingGrating_blue(tiltInDegrees, cont_idx)
% Camden MacDowell 2021
% creates static gratings at angles in tileInDegress (vector)
% cont_idx is the contrast of the grating (def=1). 
%for now, this is only coded for 0 and 90 degrees (white band)

if nargin <2
   cont_idx = ones(1,numel(tiltInDegrees)); 
end

% Get the screen numbers
AssertOpenGL;
Screen('Preference', 'SkipSyncTests', 1);
screens = Screen('Screens');

% Draw to the external screen if avaliable
opts.screenNumber = 1;

% Define black and white
black = BlackIndex(opts.screenNumber);
white = WhiteIndex(opts.screenNumber);
gray = white / 2; %camden you have checked, and this is equal to the average pixel value of each stimulus
absoluteDifferenceBetweenWhiteAndGray = abs(white - gray);
gray_blue = [0 0 gray];

% Open an on screen retinoOpts.window
[opts.window, opts.windowRect] = Screen('OpenWindow', opts.screenNumber, gray_blue);
[screenXpixels, screenYpixels] = Screen('windowSize', opts.window);

% If the grating is clipped on the sides, increase widthOfGrid.
widthOfGrid = screenXpixels*4; %make it much larger so that you can rotate and trim to size
halfWidthOfGrid = widthOfGrid / 2;
widthArray = (-halfWidthOfGrid) : halfWidthOfGrid;  % widthArray is used in creating the meshgrid.

opts.gratingtex = cell(1,numel(tiltInDegrees));
%create gratings
tiltInRadians = 0 * pi / 180; % The tilt of the grating in radians.
% To lengthen the period of the grating, increase pixelsPerPeriod.
pixelsPerPeriod = 512; %256; % for drifting grating, we need a power of 2. Used to be 190; %150; % How many pixels will each period/cycle occupy?
spatialFrequency = 1 / pixelsPerPeriod; % How many periods/cycles are there in a pixel?
radiansPerPixel = spatialFrequency * (2 * pi); % = (periods per pixel) * (2 pi radians per period)

X_drift=2^11; %size of the square for drifting grating

aspect_ratio = screenXpixels / screenYpixels;
[x, y] = meshgrid(widthArray, widthArray);
%[x_correct, y_correct] = meshgrid(widthArray / aspect_ratio, widthArray); % reflect the aspect_ratio when rotating the grating
[x_correct, y_correct] = meshgrid(widthArray / (aspect_ratio*1.5), widthArray); % reflect the aspect_ratio when rotating the grating 
% NOTE: This denominator (aspect_ratio*1.5) is empirically calibrated to
% match the spatial frequency between vertical and horizontal
% presentations. 

a=cos(tiltInRadians)*radiansPerPixel;
b=sin(tiltInRadians)*radiansPerPixel;

% Converts meshgrid into a sinusoidal grating 
imageMatrix = sin(a*x+b*y);
imageMatrix_to_rotate = sin(a*x_correct+b*y_correct);

for i = 1:numel(tiltInDegrees)
%     if tiltInDegrees(i) == 0
        %scale contrast since imageMatrix is a fraction between minus one and one
        imageMatrix_scaled=imageMatrix*cont_idx(i);

        %convert to grayscale
        grayscaleImageMatrix = gray + absoluteDifferenceBetweenWhiteAndGray * imageMatrix_scaled;    

        %crop to size of screen
        temp = imrotate(grayscaleImageMatrix,tiltInDegrees(i), 'crop');
        cent = round(size(grayscaleImageMatrix,1)/2);
    
        temp3=temp(round(cent-X_drift/2)+1:round(cent+X_drift/2),round(cent-X_drift/2)+1:round(cent+X_drift/2));

        %if tiltInDegrees(i) == 0
        temp = temp(round(cent-screenXpixels/2)+1:round(cent+screenXpixels/2),round(cent-screenYpixels/2)+1:round(cent+screenYpixels/2));
%     else
%         %scale contrast since imageMatrix is a fraction between minus one and one
%         imageMatrix_scaled=imageMatrix_to_rotate*cont_idx(i);
% 
%         %convert to grayscale
%         grayscaleImageMatrix = gray + absoluteDifferenceBetweenWhiteAndGray * imageMatrix_scaled;    
% 
%         %crop to size of screen
%         temp = imrotate(grayscaleImageMatrix,tiltInDegrees(i), 'crop');
%         cent = round(size(grayscaleImageMatrix,1)/2);
%     
%         temp3=temp(round(cent-X_drift/2)+1:round(cent+X_drift/2),round(cent-X_drift/2)+1:round(cent+X_drift/2));
% 
%         %if tiltInDegrees(i) == 0
%         temp = temp(round(cent-screenXpixels/2)+1:round(cent+screenXpixels/2),round(cent-screenYpixels/2)+1:round(cent+screenYpixels/2));
%     end

    opts.tiltInDegrees(i)=tiltInDegrees(i);
        
    %make top corner white
    temp2(:,:,1)=zeros(size(temp)); %red
    temp2(:,:,2)=zeros(size(temp)); %green
    temp2(:,:,3)=temp; %blue
    temp2(1:96,1:54,:)=255; %add a white corner

    %make white band on top or on the side
    temp4(:,:,1)=zeros(size(temp3)); %red
    temp4(:,:,2)=zeros(size(temp3)); %green
    temp4(:,:,3)=temp3; %blue
    if opts.tiltInDegrees(i)==0
        temp4(1:54,:,:)=255; %add a white band
    elseif opts.tiltInDegrees(i)==90
        temp4(:,1:54,:)=255; %add a white band
    end
    opts.gratingMatrix{i}=temp4;
    opts.gratingtex{i}=Screen('MakeTexture', opts.window, temp4,[],1);
end

opts.pixelsPerPeriod=pixelsPerPeriod;

% Perform initial Flip to sync us to the VBL and for getting an initial
% VBL-Timestamp for our "WaitBlanking" emulation:
opts.vbl=Screen('Flip', opts.window);


end









