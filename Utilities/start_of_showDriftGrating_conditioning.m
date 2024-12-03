function start_of_showDriftGrating_conditioning(opts, stim_id, cyclespersecond,  movieDurationSecs)
%Written by Caroline Jahn, 2/2/24
%based on DriftDemo2 (Psychtoolbox)
%See Drift_test for all comments + debug + details
% Parameters:
%
% cyclespersecond = Speed of grating in cycles per second.
% movieDurationSecs = length of movie in sec

% This script calls Psychtoolbox commands available only in OpenGL-based 
% versions of the Psychtoolbox. The Psychtoolbox command AssertPsychOpenGL will issue
% an error message if someone tries to execute this script on a computer without
% an OpenGL Psychtoolbox.
AssertOpenGL;

% Query duration of monitor refresh interval:
ifi=Screen('GetFlipInterval', opts.window);    
waitframes = 1;
waitduration = waitframes * ifi;

% Translate requested speed of the grating (in cycles per second)
% into a shift value in "pixels per frame", assuming given
% waitduration: This is the amount of pixels to shift our srcRect at
% each redraw:
shiftperframe= cyclespersecond * opts.pixelsPerPeriod * waitduration;

% Perform initial Flip to sync us to the VBL and for getting an initial
% VBL-Timestamp for our "WaitBlanking" emulation:
vbl=Screen('Flip', opts.window);

xoffset=0;

% Animationloop:
tic;
while toc<movieDurationSecs
   % Shift the grating by "shiftperframe" pixels per frame:
    xoffset = xoffset + shiftperframe;

   % Define shifted srcRect that cuts out the properly shifted rectangular
   % area from the texture:
   if opts.tiltInDegrees(stim_id(1))==0
       srcRect=[xoffset 0 xoffset + opts.windowRect(3) opts.windowRect(4)];
   elseif opts.tiltInDegrees(stim_id(1))==90
       srcRect=[0 xoffset opts.windowRect(3) xoffset + opts.windowRect(4)];
   end

   % Draw grating texture: Only show subarea 'srcRect', center texture in
   % the onscreen window automatically:
    Screen('DrawTexture', opts.window, opts.gratingtex{stim_id(1)}, srcRect)  %opts.gratingtex{dir_seq(1)}   

   % Flip 'waitframes' monitor refresh intervals after last redraw.
   vbl = Screen('Flip', opts.window, vbl + (waitframes - 0.5) * ifi);

end
toc;

% go back to background when done
Screen('Flip', opts.window);

