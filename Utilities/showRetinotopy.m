function showRetinotopy(retinoOpts, direction) 

%Duration needs to be in seconds
retinoOpts.vbl=Screen('Flip', retinoOpts.window);

for i = 1:retinoOpts.nsteps
   srcRect = retinoOpts.srcRect{direction,i};
    Screen('DrawTextures', retinoOpts.window, [retinoOpts.timetex{1},... %replace {1} with retinoOpts.texIndex{i} to flicker as well and get frequency of flickering
        retinoOpts.basetex{retinoOpts.texIndex(i)}],...
        [retinoOpts.windowRect',srcRect'], [retinoOpts.windowRect',srcRect'],[0,0]);    
   retinoOpts.vbl = Screen('Flip', retinoOpts.window, retinoOpts.vbl - 0.5 * retinoOpts.ifi);
end

Screen('Flip', retinoOpts.window);

end

