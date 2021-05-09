%TO DO. 
% Intergrate within functions 
% Then test with photodiode
% then run with example animal and see if works.

gratingOpts.BackgroundColor = 0.1; %in terms of black/white gradient 
gratingOpts.cyclespersecond = 9; %Grating speed -- cycles per second
gratingOpts.Angles = [0 180]; %angle of grating (in degrees)
gratingOpts.StimulusTime = 1; %in seconds
gratingOpts.stimDuration = 3;
gratingOpts.visiblesize=1024;        % Size of the grating image. Needs to be a power of two.
gratingOpts.p = 102.4; 
gratingOpts.GaborContrast = .4; %in terms of range from white to gray
gratingOpts.BackgroundColor2 = 0.5;

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Get the screen numbers
screens = Screen('Screens');

% Draw to the external screen if avaliable
screenNumber = max(screens);

% Define black and white
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
gray = white / 2;

% Open an on screen window
[window, windowRect] = Screen('OpenWindow', screenNumber, gray);
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

%Create a base checkerboard by stacking 100x100 pixels on top of each other
N=100;
baseRect = repmat(cat(1,[ones(N), zeros(N)], [zeros(N), ones(N)]),10,10);

% Trim to match screen dimensions
baseRect_ivt = baseRect(1:screenXpixels,1:screenXpixels)<0.5;
baseRect = baseRect(1:screenXpixels,1:screenXpixels)>0.5;

%convert to RBG
baseRect = 255 * repmat(uint8(baseRect), 1, 1, 3);
baseRect_ivt = 255 * repmat(uint8(baseRect_ivt), 1, 1, 3);

% Create a texture from the imaging
gratingOpts.gratingtex=Screen('MakeTexture', window, baseRect);
gratingOpts.gratingtex2=Screen('MakeTexture', window, baseRect_ivt);
Screen('DrawTexture', window, gratingOpts.gratingtex,[0, 0, size(baseRect,1),size(baseRect,2)],[windowRect],0);
Screen('Flip', window);

% Calculate parameters of the grating:
f=1/gratingOpts.p;
fr=f*2*pi;    % frequency in radians.

gratingOpts.ifi=Screen('GetFlipInterval', window);    
gratingOpts.waitframes = 1;
gratingOpts.waitduration = gratingOpts.waitframes * gratingOpts.ifi;
gratingOpts.shiftperframe= gratingOpts.cyclespersecond * gratingOpts.p * gratingOpts.waitduration;

gratingOpts.vbl=Screen('Flip', window);
%%
gratingOpts.xoffset=0; %horizontal right
gratingOpts.xoffset=1920; %horizontal left
gratingOpts.yoffset=1080; %vert b to top
gratingOpts.yoffset=0; %vert top to bottom
temp =0;
flicker = 0
% Now draw
tic
duration =2
while(toc<duration) %(gratingOpts.vbl < gratingOpts.vblendtime)
   temp = temp+1;
   if mod(temp,10)==0
       flicker = flicker+1;
   end
          
   % Shift the grating by "shiftperframe" pixels per frame:
%    gratingOpts.xoffset = gratingOpts.xoffset + gratingOpts.shiftperframe; %horizontal right
%    gratingOpts.xoffset = gratingOpts.xoffset - gratingOpts.shiftperframe; %horizontal left
%    gratingOpts.yoffset = gratingOpts.yoffset - gratingOpts.shiftperframe; %vert b to top
   gratingOpts.yoffset = gratingOpts.yoffset + gratingOpts.shiftperframe; %vert top to b

   % Define shifted srcRect that cuts out the properly shifted rectangular
   % area from the texture:
%    srcRect=[gratingOpts.xoffset 0 gratingOpts.xoffset + 150 1080]; %horz
   srcRect=[0 gratingOpts.yoffset 1920 gratingOpts.yoffset + 150]; %vert

   % Draw grating texture: Only show subarea 'srcRect', center texture in
   % the onscreen window automatically:
   %Screen('DrawTexture', w, gratingtex, srcRect);
   if mod(flicker,2)==0
       Screen('DrawTexture', window, gratingOpts.gratingtex, srcRect,srcRect, gratingOpts.Angles(1));
   else
       Screen('DrawTexture', window, gratingOpts.gratingtex2, srcRect,srcRect, gratingOpts.Angles(1));
   end

   % Flip 'waitframes' monitor refresh intervals after last redraw.
   gratingOpts.vbl = Screen('Flip', window, gratingOpts.vbl + (gratingOpts.waitframes - 0.5) * gratingOpts.ifi);
end
gratingOpts.vbl=Screen('Flip', window);

%%

screenRes = Screen('Resolution',screenNumber)
d = 100
barWcm = 2*d*tan(5/2*pi/180);  %bar width in cm
barLcm = 2*d*tan(10/2*pi/180);  %bar length in cm

Im = makeBar(barWcm,barLcm,0)

