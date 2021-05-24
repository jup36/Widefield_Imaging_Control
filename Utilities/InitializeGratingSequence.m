function [opts] = InitializeGratingSequence()
% Camden MacDowell 2018
if nargin <1
    opts.cyclespersecond = 5; %Grating speed -- cycles per second
    opts.duration = 0.4667; %in seconds
    opts.visiblesize=1024;        % Size of the grating image. Needs to be a power of two.
    opts.p = 102.4; 
    opts.GaborContrast = .4; %in terms of range from white to gray
end

if rem(opts.visiblesize, opts.p)~=0
  error('Period p must divide default visiblesize of 1024 pixels without remainder for this demo to work!');
end

% Get the screen numbers
AssertOpenGL;
Screen('Preference', 'SkipSyncTests', 0);
screens = Screen('Screens');

% Draw to the external screen if avaliable
opts.screenNumber = max(screens);

% Define black and white
black = BlackIndex(opts.screenNumber);
white = WhiteIndex(opts.screenNumber);
opts.gray = white / 2;

% Contrast 'inc'rement range for given white and gray values:
opts.inc = min(opts.GaborContrast*(white - opts.gray), opts.GaborContrast*(opts.gray - black));

% Open an on screen retinoOpts.window
[opts.window, opts.windowRect] = Screen('OpenWindow', opts.screenNumber, black);
[screenXpixels,screenYpixels] = Screen('windowSize', opts.window);

% Create small white rectangle for photodiode
timeRect = false(screenXpixels,screenYpixels);
timeRect(1:100,1:100)=true;
opts.timetex = Screen('MakeTexture',opts.window,255 * repmat(uint8(timeRect), 1, 1, 3));

% Calculate parameters of the grating:
f=1/opts.p;
fr=f*2*pi;    % frequency in radians.

% Create one single static 1-D grating image.
x=meshgrid(0:opts.visiblesize-1, 1);
opts.grating=opts.gray + opts.inc*cos(fr*x);

% Store grating in texture: Set the 'enforcepot' flag to 1 to signal
% Psychtoolbox that we want a special scrollable power-of-two texture:
opts.gratingtex=Screen('MakeTexture', opts.window, opts.grating,[],1);

% Query duration of monitor refresh interval:
opts.ifi=Screen('GetFlipInterval', opts.window);    

% Get shift per frame
opts.shiftperframe = opts.cyclespersecond * opts.p * opts.ifi;

%get total number of frames
opts.nsteps = round(opts.duration/opts.ifi,0);

% Perform initial Flip to sync us to the VBL and for getting an initial
% VBL-Timestamp for our "WaitBlanking" emulation:
opts.vbl=Screen('Flip', opts.window);

% create horizational grating index
opts.srcRect = cell(1,opts.nsteps);
offset=0; 
for i = 1:opts.nsteps
    offset = offset + opts.shiftperframe;
    opts.srcRect{1,i}=[offset 0 offset + opts.visiblesize opts.visiblesize];
end

end









