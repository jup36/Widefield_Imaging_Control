function start_of_showGrating_conditioning(opts,dir_seq) 
%%  direction is 1,2,3,4,etc
Screen('DrawTexture', opts.window, opts.gratingtex{dir_seq(1)}, [], opts.windowRect)
% Screen('DrawTexture', opts.window, 15, [], opts.windowRect)
opts.vbl = Screen('Flip', opts.window);
% WaitSecs(isi);
% Screen('DrawTexture',opts.window,opts.gratingtex{dir_seq(2)},[],opts.windowRect)
% opts.vbl = Screen('Flip', opts.window);
% WaitSecs(dur);
% Screen('Flip', opts.window);

end

