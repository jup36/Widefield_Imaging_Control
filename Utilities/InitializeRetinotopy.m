function [retinoOpts] = InitializeRetinotopy(duration, barthickness)
% Camden MacDowell 2021
% This initializes all the grating parameters and starts psych toolbox 
% this is barebone retinotopic mapping designed to only identify V1. If entire retinotopy
% is desired then one need to use larger stimulus FOV and warp both the
% background checkerboard and the the bar to simuluate circular space on
% flat screen. 

%initialize options
retinoOpts.duration = duration; %time to traverse the screen
retinoOpts.barthickness = barthickness; %width (horz) or height (vert) of bar i pixels
retinoOpts.N = 100; %size of checkboard squares in pixels (def =100)
retinoOpts.flickerfrequency = 7; %rate to reverse contrast in HZ

% Get the screen numbers
AssertOpenGL;
Screen('Preference', 'SkipSyncTests', 0);
screens = Screen('Screens');

% Draw to the external screen if avaliable
retinoOpts.screenNumber = max(screens);

% Define black and white
white = WhiteIndex(retinoOpts.screenNumber);
black = BlackIndex(retinoOpts.screenNumber);
gray = white / 2;

% Open an on screen retinoOpts.window
[retinoOpts.window, retinoOpts.windowRect] = Screen('OpenWindow', retinoOpts.screenNumber, black);
[screenXpixels,screenYpixels] = Screen('windowSize', retinoOpts.window);

%Create a base checkerboard by stacking NxN pixel boxes on top of each other
baseRect = repmat(cat(1,[ones(retinoOpts.N), zeros(retinoOpts.N)], [zeros(retinoOpts.N), ones(retinoOpts.N)]),10,10);

% Trim by the x dimension to make rectanlge that match aspect ratio
baseRect = baseRect(1:screenXpixels,1:screenXpixels);

% Create reversal textures
retinoOpts.basetex{1}=Screen('MakeTexture', retinoOpts.window, 255 * repmat(uint8(baseRect>0.5), 1, 1, 3));
retinoOpts.basetex{2}=Screen('MakeTexture', retinoOpts.window, 255 * repmat(uint8(baseRect<0.5), 1, 1, 3));

% Create small white rectangle for photodiode
timeRect = false(size(baseRect));
retinoOpts.timetex{2} = Screen('MakeTexture',retinoOpts.window,255 * repmat(uint8(timeRect), 1, 1, 3));
timeRect(1:100,1:100)=true;
retinoOpts.timetex{1} = Screen('MakeTexture',retinoOpts.window,255 * repmat(uint8(timeRect), 1, 1, 3));


% Get the speed to traverse the screen
retinoOpts.ifi=Screen('GetFlipInterval', retinoOpts.window);    

% shiftper frame so that it traverses the entire screen during the duration
retinoOpts.nsteps = round(retinoOpts.duration/retinoOpts.ifi,0);

% Presentation starts and ends with full bar width on screen so subtract
retinoOpts.shiftperframe = ceil([screenXpixels-retinoOpts.barthickness*2,screenYpixels-retinoOpts.barthickness*2]/(retinoOpts.nsteps)); %[horz, vert]

% compute the frame interval to switch contrast
retinoOpts.flickerFramesInterval = round((retinoOpts.nsteps/retinoOpts.flickerfrequency)/retinoOpts.duration,0);

retinoOpts.vbl=Screen('Flip', retinoOpts.window);

% Get sequence of textures per step
total_reversals = round(retinoOpts.nsteps/retinoOpts.flickerFramesInterval/2,0);
retinoOpts.texIndex = repmat([ones(1,retinoOpts.flickerFramesInterval),ones(1,retinoOpts.flickerFramesInterval)*2],1,total_reversals*2);

%trim to deal with any incomplete reversals
retinoOpts.texIndex = retinoOpts.texIndex(1:retinoOpts.nsteps);

% Get the rectanlge locations per step for all four cardinal directions
retinoOpts.srcRect = cell(4,retinoOpts.nsteps);
%left to right
offset=0; %horizontal right
for i = 1:retinoOpts.nsteps
    offset = offset + retinoOpts.shiftperframe(1);
    retinoOpts.srcRect{1,i}=[offset 0 offset + retinoOpts.barthickness 1080];
end
%right to left
offset=1920; 
for i = 1:retinoOpts.nsteps
    offset = offset - retinoOpts.shiftperframe(1);
    retinoOpts.srcRect{2,i}=[offset 0 offset + retinoOpts.barthickness 1080];
end
%bottom to top
offset=1080; 
for i = 1:retinoOpts.nsteps
    offset = offset - retinoOpts.shiftperframe(2);
    retinoOpts.srcRect{3,i}=[0 offset 1920 offset + retinoOpts.barthickness];
end
%top to bottom
offset=0; 
for i = 1:retinoOpts.nsteps
    offset = offset + retinoOpts.shiftperframe(2);
    retinoOpts.srcRect{4,i}=[0 offset 1920 offset + retinoOpts.barthickness];
end

end

