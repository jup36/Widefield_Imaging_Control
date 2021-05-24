function showGratingSequence(opts,direction) 
%%
%Duration needs to be in seconds
opts.vbl=Screen('Flip', opts.window);

for i = 1:opts.nsteps
   srcRect = opts.srcRect{i};
   Screen('DrawTextures', opts.window, [opts.timetex,... %replace {1} with retinoOpts.texIndex{i} to flicker as well and get frequency of flickering
        opts.gratingtex],...
        [opts.windowRect',srcRect'], [opts.windowRect',opts.windowRect'],[0,direction]);    
   opts.vbl = Screen('Flip', opts.window, opts.vbl - 0.5 * opts.ifi);
end

Screen('Flip', opts.window);
%%
end

