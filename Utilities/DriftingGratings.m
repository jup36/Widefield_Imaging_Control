function DriftingGratings(opts,Duration,cyclespersecond, p)
% Camden MacDowell 2018
% function DriftDemo3([cyclespersecond=1][, p=32])
% Adapted from DriftDemo3 of psych toolbox. Refer to that demo for
% additional informaiton 


if nargin < 2
    cyclespersecond = [];
end

if isempty(cyclespersecond)
    % Default speed of grating in cycles per second:
    cyclespersecond=8;
end

if nargin < 3
    % Default grating spatial period:
    p=64;
end;

movieDurationSecs=Duration;   % Abort demo after 60 seconds.
visiblesize=1024;        % Size of the grating image. Needs to be a power of two.

if rem(visiblesize, p)~=0
  error('Period p must divide default visiblesize of 512 pixels without remainder for this demo to work!');
end;

% This script calls Psychtoolbox commands available only in OpenGL-based 
% versions of the Psychtoolbox. The Psychtoolbox command AssertPsychOpenGL will issue
% an error message if someone tries to execute this script on a computer without
% an OpenGL Psychtoolbox.
AssertOpenGL;

% Get the list of screens and choose the one with the highest screen number.
% Screen 0 is, by definition, the display with the menu bar. Often when 
% two monitors are connected the one without the menu bar is used as 
% the stimulus display.  Chosing the display with the highest dislay number is 
% a best guess about where you want the stimulus displayed.  
screens=Screen('Screens');
screenNumber=max(screens);

% Find the color values which correspond to white and black: Usually
% black is always 0 and white 255, but this rule is not true if one of
% the high precision framebuffer modes is enabled via the
% PsychImaging() commmand, so we query the true values via the
% functions WhiteIndex and BlackIndex:
white=WhiteIndex(screenNumber);
black=BlackIndex(screenNumber);

% Round gray to integral number, to avoid roundoff artifacts with some
% graphics cards:
gray=round((white+black)/2);

% This makes sure that on floating point framebuffers we still get a
% well defined gray. It isn't strictly neccessary in this demo:
if gray == white
    gray=white / 2;
end

% Contrast 'inc'rement range for given white and gray values:
inc=white-gray;

% Open a double buffered fullscreen window and draw a gray background 
% to front and back buffers as background clear color:
w = Screen('OpenWindow',screenNumber, gray);

% Calculate parameters of the grating:
f=1/p;
fr=f*2*pi;    % frequency in radians.

% Create one single static 1-D grating image.
% We only need a texture with a single row of pixels(i.e. 1 pixel in height) to
% define the whole grating! If the 'srcRect' in the 'Drawtexture' call
% below is "higher" than that (i.e. visibleSize >> 1), the GPU will
% automatically replicate pixel rows. This 1 pixel height saves memory
% and memory bandwith, ie. it is potentially faster on some GPUs.
x=meshgrid(0:visiblesize-1, 1);
grating=gray + inc*cos(fr*x);

% Store grating in texture: Set the 'enforcepot' flag to 1 to signal
% Psychtoolbox that we want a special scrollable power-of-two texture:
gratingtex=Screen('MakeTexture', w, grating, [], 1);

% Query duration of monitor refresh interval:
ifi=Screen('GetFlipInterval', w);    
waitframes = 1;
waitduration = waitframes * ifi;

% Translate requested speed of the grating (in cycles per second)
% into a shift value in "pixels per frame", assuming given
% waitduration: This is the amount of pixels to shift our srcRect at
% each redraw:
shiftperframe= cyclespersecond * p * waitduration;

% Perform initial Flip to sync us to the VBL and for getting an initial
% VBL-Timestamp for our "WaitBlanking" emulation:
vbl=Screen('Flip', w);

% We run at most 'movieDurationSecs' seconds if user doesn't abort via keypress.
vblendtime = vbl + movieDurationSecs;
xoffset=0;

%%dstRect = [0 0 visiblesize visiblesize];%-1000 -1000 3000 3000
%dstRect = CenterRect(dstRect, screenRect);
%dstRect([1 2]) = dstRect([1 2]) + opts.GratingPosition;

% Animationloop:
while(vbl < vblendtime)
   % Shift the grating by "shiftperframe" pixels per frame:
   xoffset = xoffset + shiftperframe;

   % Define shifted srcRect that cuts out the properly shifted rectangular
   % area from the texture:
   srcRect=[xoffset 0 xoffset + visiblesize visiblesize];

   % Draw grating texture: Only show subarea 'srcRect', center texture in
   % the onscreen window automatically:
   %Screen('DrawTexture', w, gratingtex, srcRect);
   Screen('DrawTexture', w, gratingtex, srcRect,[], opts.Angles(3));

   % Flip 'waitframes' monitor refresh intervals after last redraw.
   vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);

   % Abort demo if any key is pressed:
   if KbCheck
      break;
   end;
end;

% The same commands wich close onscreen and offscreen windows also close
% textures.
sca;

% Well done!
return;
