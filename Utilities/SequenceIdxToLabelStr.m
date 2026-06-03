function str = SequenceIdxToLabelStr(idxVec, stimNames)
% Convert stimulus index vector to comma-joined label string.
% 0 = blank (space), -1 = '$', positive = stimNames{idx}.

idxVec = idxVec(:).';
parts = cell(1, numel(idxVec));
for j = 1:numel(idxVec)
    v = idxVec(j);
    if v == 0
        parts{j} = ' ';
    elseif v == -1
        parts{j} = '$';
    elseif v >= 1 && v <= numel(stimNames)
        parts{j} = stimNames{v};
    else
        parts{j} = sprintf('?%d', v);
    end
end
str = strjoin(parts, ',');

end
