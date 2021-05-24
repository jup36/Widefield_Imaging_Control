function showRetinotopy(opts, direction) 

%Duration needs to be in seconds
opts.vbl=Screen('Flip', opts.window);

for i = 1:opts.nsteps
   srcRect = opts.srcRect{direction,i};
   Screen('DrawTextures', opts.window, [opts.timetex{1},... %replace {1} with retinoOpts.texIndex{i} to flicker as well and get frequency of flickering
        opts.basetex{opts.texIndex(i)}],...
        [opts.windowRect',srcRect'], [opts.windowRect',srcRect'],[0,0]);    
   opts.vbl = Screen('Flip', opts.window, opts.vbl - 0.5 * opts.ifi);
end

Screen('Flip', opts.window);

end

