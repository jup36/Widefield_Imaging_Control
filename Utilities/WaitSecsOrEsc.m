function aborted = WaitSecsOrEsc(seconds)
% Wait up to seconds wall time; return true if ESC is pressed (Psychtoolbox KbCheck).
% Requires PTB (GetSecs, KbCheck). Use with RestrictKeysForKbCheck(KbName('ESCAPE')) optional.

aborted = false;
if nargin < 1 || seconds <= 0
    return
end

persistent escKey
if isempty(escKey)
    try
        KbName('UnifyKeyNames');
    catch
    end
    try
        escKey = KbName('ESCAPE');
    catch
        escKey = [];
    end
end
if isempty(escKey)
    WaitSecs(seconds);
    return
end

tEnd = GetSecs + seconds;
while GetSecs < tEnd
    [down, ~, keyCode] = KbCheck(-1);
    if down && any(keyCode(escKey))
        aborted = true;
        return
    end
    WaitSecs(0.01);
end

end
