function [gratingOpts] = InitializeGratings(duration_sec)
% Camden MacDowell 2018
% This initializes all the grating parameters and starts psych toolbox 
% Adapted from DriftDemo3 of psych toolbox. Refer to that demo for
% additional informaiton 
if nargin <1
    duration_sec = 1; %set default stim duraiton
end
gratingOpts.BackgroundColor = 0.1; %in terms of black/white gradient 
gratingOpts.cyclespersecond = 9; %Grating speed -- cycles per second
gratingOpts.Angles = [0 180]; %angle of grating (in degrees)
gratingOpts.StimulusTime = 1; %in seconds
gratingOpts.stimDuration = duration_sec;
gratingOpts.visiblesize=1024;        % Size of the grating image. Needs to be a power of two.
gratingOpts.p = 102.4; 
gratingOpts.GaborContrast = .4; %in terms of range from white to gray
gratingOpts.BackgroundColor2 = 0.5;

if rem(gratingOpts.visiblesize, gratingOpts.p)~=0
  error('Period p must divide default visiblesize of 1024 pixels without remainder for this demo to work!');
end

% This script calls Psychtoolbox commands available only in OpenGL-based 
% versions of the Psychtoolbox. The Psychtoolbox command AssertPsychOpenGL will issue
% an error message if someone tries to execute this script on a computer without
% an OpenGL Psychtoolbox.
AssertOpenGL;
%Screen('Preference', 'SkipSyncTests', 0);
Screen('Preference', 'SkipSyncTests', 1);
%Show the stim on the tiny mouse monitor (Usually monitor 1); 
screens=Screen('Screens');
gratingOpts.screenNumber=max(screens); %max(screens);

% Find the color values which correspond to white and black: Usually
% black is always 0 and white 255, but this rule is not true if one of
% the high precision framebuffer modes is enabled via the
% PsychImaging() commmand, so we query the true values via the
% functions WhiteIndex and BlackIndex:
white=WhiteIndex(gratingOpts.screenNumber);
black=BlackIndex(gratingOpts.screenNumber);

% Round gray to integral number, to avoid roundoff artifacts with some
% graphics cards:
% gratingOpts.gray=round((white+black)/2)*gratingOpts.BackgroundColor;

% Round gray to integral number, to avoid roundoff artifacts with some
% graphics cards:
gratingOpts.gray = round(black + (white - black)*gratingOpts.BackgroundColor2);

% Contrast 'inc'rement range for given white and gray values:
gratingOpts.inc = min(gratingOpts.GaborContrast*(white - gratingOpts.gray), gratingOpts.GaborContrast*(gratingOpts.gray - black));


% % This makes sure that on floating point framebuffers we still get a
% % well defined gray. It isn't strictly neccessary in this demo:
% if gratingOpts.gray == white
%     gratingOpts.gray=white / 2;
% end
% 
% % Contrast 'inc'rement range for given white and gray values:
% gratingOpts.inc=white-gratingOpts.gray;

% Open a double buffered fullscreen window and draw a gray background 
% to front and back buffers as background clear color:
gratingOpts.w = Screen('OpenWindow',gratingOpts.screenNumber, (gratingOpts.gray*0.1));

% Calculate parameters of the grating:
f=1/gratingOpts.p;
fr=f*2*pi;    % frequency in radians.

% Create one single static 1-D grating image.
% We only need a texture with a single row of pixels(i.e. 1 pixel in height) to
% define the whole grating! If the 'srcRect' in the 'Drawtexture' call
% below is "higher" than that (i.e. visibleSize >> 1), the GPU will
% automatically replicate pixel rows. This 1 pixel height saves memory
% and memory bandwith, ie. it is potentially faster on some GPUs.
x=meshgrid(0:gratingOpts.visiblesize-1, 1);
gratingOpts.grating=gratingOpts.gray + gratingOpts.inc*cos(fr*x);

% Store grating in texture: Set the 'enforcepot' flag to 1 to signal
% Psychtoolbox that we want a special scrollable power-of-two texture:
gratingOpts.gratingtex=Screen('MakeTexture', gratingOpts.w, gratingOpts.grating, [], 1);

% Query duration of monitor refresh interval:
gratingOpts.ifi=Screen('GetFlipInterval', gratingOpts.w);    
gratingOpts.waitframes = 1;
gratingOpts.waitduration = gratingOpts.waitframes * gratingOpts.ifi;

% Translate requested speed of the grating (in cycles per second)
% into a shift value in "pixels per frame", assuming given
% waitduration: This is the amount of pixels to shift our srcRect at
% each redraw:
gratingOpts.shiftperframe= gratingOpts.cyclespersecond * gratingOpts.p * gratingOpts.waitduration;

% Perform initial Flip to sync us to the VBL and for getting an initial
% VBL-Timestamp for our "WaitBlanking" emulation:
gratingOpts.vbl=Screen('Flip', gratingOpts.w);

% We run at most 'grateingOpts.stimDuration' seconds if user doesn't abort via keypress.
gratingOpts.vblendtime = gratingOpts.vbl + gratingOpts.stimDuration;
gratingOpts.xoffset=0;


% The same commands wich close onscreen and offscreen windows also close
% textures.
%sca;

% Well done!
end
