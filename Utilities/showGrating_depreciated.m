function showGrating_depreciated(gratingOpts,anglechoice,duration) 

%Duration needs to be in seconds

gratingOpts.vbl=Screen('Flip', gratingOpts.w);

% We run at most 'grateingOpts.stimDuration' seconds if user doesn't abort via keypress.
gratingOpts.vblendtime = gratingOpts.vbl + gratingOpts.stimDuration;
gratingOpts.xoffset=0;

% Animationloop:
tic
while(toc<duration) %(gratingOpts.vbl < gratingOpts.vblendtime)
   % Shift the grating by "shiftperframe" pixels per frame:
   gratingOpts.xoffset = gratingOpts.xoffset + gratingOpts.shiftperframe;

   % Define shifted srcRect that cuts out the properly shifted rectangular
   % area from the texture:
   srcRect=[gratingOpts.xoffset 0 gratingOpts.xoffset + gratingOpts.visiblesize gratingOpts.visiblesize];

   % Draw grating texture: Only show subarea 'srcRect', center texture in
   % the onscreen window automatically:
   %Screen('DrawTexture', w, gratingtex, srcRect);
   Screen('DrawTexture', gratingOpts.w, gratingOpts.gratingtex, srcRect,[], gratingOpts.Angles(anglechoice));

   % Flip 'waitframes' monitor refresh intervals after last redraw.
   gratingOpts.vbl = Screen('Flip', gratingOpts.w, gratingOpts.vbl + (gratingOpts.waitframes - 0.5) * gratingOpts.ifi);
end
    
%gratingOpts.gratingtex=Screen('MakeTexture', gratingOpts.w, (gratingOpts.gray*gratingOpts.BackgroundColor));
%Screen('Close', gratingOpts.gratingtex);
Screen('Flip', gratingOpts.w);

end

