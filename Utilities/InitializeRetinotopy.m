function [opts] = InitializeRetinotopy(duration, barthickness)
% Camden MacDowell 2021
% This initializes all the grating parameters and starts psych toolbox 
% this is barebone retinotopic mapping designed to only identify V1. If entire retinotopy
% is desired then one need to use larger stimulus FOV and warp both the
% background checkerboard and the the bar to simuluate circular space on
% flat screen. 

%initialize options
opts.duration = duration; %time to traverse the screen
opts.barthickness = barthickness; %width (horz) or height (vert) of bar i pixels
opts.N = 100; %size of checkboard squares in pixels (def =100)
opts.flickerfrequency = 7; %rate to reverse contrast in HZ

% Get the screen numbers
AssertOpenGL;
Screen('Preference', 'SkipSyncTests', 1);
screens = Screen('Screens');

% Draw to the external screen if avaliable
opts.screenNumber = max(screens);

% Define black and white
black = BlackIndex(opts.screenNumber);
white = WhiteIndex(opts.screenNumber);
gray = white/2;

% Open an on screen retinoOpts.window
[opts.window, opts.windowRect] = Screen('OpenWindow', opts.screenNumber, gray);
[screenXpixels,screenYpixels] = Screen('windowSize', opts.window);

%Create a base checkerboard by stacking NxN pixel boxes on top of each other
baseRect = repmat(cat(1,[ones(opts.N), zeros(opts.N)], [zeros(opts.N), ones(opts.N)]),10,10);

% Trim by the x dimension to make rectanlge that match aspect ratio
baseRect = baseRect(1:screenXpixels,1:screenXpixels);

% Create reversal textures
opts.basetex{1}=Screen('MakeTexture', opts.window, 255 * repmat(uint8(baseRect>0.5), 1, 1, 3));
opts.basetex{2}=Screen('MakeTexture', opts.window, 255 * repmat(uint8(baseRect<0.5), 1, 1, 3));

% Create small white rectangle for photodiode
timeRect = false(size(baseRect));
opts.timetex{2} = Screen('MakeTexture',opts.window,255 * repmat(uint8(timeRect), 1, 1, 3));
timeRect(1:100,1:100)=true;
opts.timetex{1} = Screen('MakeTexture',opts.window,255 * repmat(uint8(timeRect), 1, 1, 3));


% Get the speed to traverse the screen
opts.ifi=Screen('GetFlipInterval', opts.window);    

% shiftper frame so that it traverses the entire screen during the duration
opts.nsteps = round(opts.duration/opts.ifi,0);

% Presentation starts and ends with full bar width on screen so subtract
opts.shiftperframe = ceil([screenXpixels-opts.barthickness*2,screenYpixels-opts.barthickness*2]/(opts.nsteps)); %[horz, vert]

% compute the frame interval to switch contrast
opts.flickerFramesInterval = round((opts.nsteps/opts.flickerfrequency)/opts.duration,0);

opts.vbl=Screen('Flip', opts.window);

% Get sequence of textures per step
total_reversals = round(opts.nsteps/opts.flickerFramesInterval/2,0);
opts.texIndex = repmat([ones(1,opts.flickerFramesInterval),ones(1,opts.flickerFramesInterval)*2],1,total_reversals*2);

%trim to deal with any incomplete reversals
opts.texIndex = opts.texIndex(1:opts.nsteps);

% Get the rectanlge locations per step for all four cardinal directions
opts.srcRect = cell(4,opts.nsteps);
%left to right
offset=0; %horizontal right
for i = 1:opts.nsteps
    offset = offset + opts.shiftperframe(1);
    opts.srcRect{1,i}=[offset 0 offset + opts.barthickness 1080];
end
%right to left
offset=1920-opts.barthickness; 
for i = 1:opts.nsteps
    offset = offset - opts.shiftperframe(1);
    opts.srcRect{2,i}=[offset 0 offset + opts.barthickness 1080];
end
%bottom to top
offset=1080-opts.barthickness; 
for i = 1:opts.nsteps
    offset = offset - opts.shiftperframe(2);
    opts.srcRect{3,i}=[0 offset 1920 offset + opts.barthickness];
end
%top to bottom
offset=0; 
for i = 1:opts.nsteps
    offset = offset + opts.shiftperframe(2);
    opts.srcRect{4,i}=[0 offset 1920 offset + opts.barthickness];
end

end

