function aborted = showGrating(opts, dir_seq, dur, isi, s)
%% Present one or more static gratings in order (texture indices in dir_seq).
% Optional 5th arg s: analog out session for per-frame triggers; omit if unused.
%
% dir_seq: row or column vector of indices into opts.gratingtex
%   0 = blank (isoluminant gray). -1 = random grating (uniform over textures, with replacement
%   each time that slot is shown — new draw every presentation of the slot).
% dur: seconds each grating is on
% isi: seconds gray between consecutive gratings (ignored after the last)
% aborted: true if user pressed ESC during presentation

if nargin < 5
    s = [];
end
aborted = false;
dir_seq = dir_seq(:).';
n = numel(dir_seq);
if n < 1
    error('showGrating:EmptySequence', 'dir_seq must list at least one stimulus index.');
end

nTex = numel(opts.gratingtex);
for k = 1:n
    if ~isempty(s)
        outputSingleScan(s,2); %deliver the trigger stimuli (2V)
        WaitSecsOrEsc(0.01); %wait 10ms
        outputSingleScan(s,0); %deliver the trigger stimuli
    end

    slot = dir_seq(k);
    if slot == 0
        bg = backgroundGrayFromOpts(opts);
        Screen('FillRect', opts.window, bg, opts.windowRect);
    elseif slot == -1
        if nTex < 1
            error('showGrating:NoTextures', 'No gratings defined for random ($) slot.');
        end
        pick = randi(nTex);
        Screen('DrawTexture',opts.window,opts.gratingtex{pick},[],opts.windowRect);
    else
        Screen('DrawTexture',opts.window,opts.gratingtex{slot},[],opts.windowRect);
    end
    opts.vbl = Screen('Flip', opts.window);

    if WaitSecsOrEsc(dur)
        aborted = true;
        bgEnd = backgroundGrayFromOpts(opts);
        Screen('FillRect', opts.window, bgEnd, opts.windowRect);
        Screen('Flip', opts.window);
        return
    end

    bgIsi = backgroundGrayFromOpts(opts);
    Screen('FillRect', opts.window, bgIsi, opts.windowRect);
    Screen('Flip', opts.window);
    if k < n
        if WaitSecsOrEsc(isi)
            aborted = true;
            return
        end
    end

end

end

function bg = backgroundGrayFromOpts(opts)
if isfield(opts, 'backgroundGray') && ~isempty(opts.backgroundGray)
    bg = opts.backgroundGray;
    return
end
sn = Screen('WindowScreenNumber', opts.window);
bg = WhiteIndex(sn) / 2;
end
