function resolved = ResolveRandomStimulusSlots(idxVec, nStim)
% Replace -1 (random-slot marker) with randi(nStim); 0 (blank) and fixed indices unchanged.
% idxVec: row or column vector of integers.

resolved = idxVec(:).';
for j = 1:numel(resolved)
    if resolved(j) == -1
        resolved(j) = randi(nStim);
    end
end

end
