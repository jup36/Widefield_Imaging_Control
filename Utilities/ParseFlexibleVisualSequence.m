function [seqopts, stim_type_cell, errMsg] = ParseFlexibleVisualSequence(cv)
% Parse GUI-defined flexible visual sequences for visual_sequence_flexible*.
%
% cv.flex_stim_definition: multiline text, one stimulus per line:
%   name,angle_deg,contrast
%   Lines starting with # are comments. Lines can also be separated by ';'.
%
% cv.flex_sequence_definition: one sequence type per line:
%   probability,name1,name2,...   (comma-separated; first field is prob)
%   Example: 0.5,A,A,B,B  for sequence AABB with prob 0.5
%   Blank slot (gray background, same duration as a grating): empty field, or only spaces
%   between commas, e.g. 0.5,A, ,C,D  or  0.5,A,,C,D
%   Random stimulus (uniform with replacement over all defined stims): use token $
%   e.g. 0.5,$,$,$,$ — four independent random gratings per trial (resolved at display time).
%
% seqopts.trial_sequence_label_index: length N, integer 1..num_sequence_types — which sequence
%   definition line (order in flex_sequence_definition) each trial was drawn from.
% seqopts also stores raw flex_* text, sequence_prob, and sequence_token_cells (string tokens
%   per sequence type, e.g. {'A','B',' ','$'}).
%
% Timing (optional fields on cv):
%   flex_stim_duration, flex_isi, flex_post_trial (seconds)
%   number_trials (scalar)

errMsg = '';
stim_type_cell = {};
seqopts = struct();

seqopts.flex_stim_duration = readScalarField(cv, 'flex_stim_duration', 0.25);
seqopts.flex_isi = readScalarField(cv, 'flex_isi', 0.466);
seqopts.flex_post_trial = readScalarField(cv, 'flex_post_trial', 2);

rawStim = flexCharField(cv, 'flex_stim_definition', '');
rawSeq = flexCharField(cv, 'flex_sequence_definition', '');
N = round(readScalarField(cv, 'number_trials', 700));
if N < 1
    errMsg = 'number_trials must be at least 1.';
    return
end

[stimNames, angles, contrasts, errMsg] = parseStimDefinition(rawStim);
if ~isempty(errMsg)
    return
end

[probs, stimLists, seqLabels, tokenCells, errMsg] = parseSequenceDefinition(rawSeq, stimNames);
if ~isempty(errMsg)
    return
end

probSum = sum(probs);
if probSum <= 0
    errMsg = 'Sequence probabilities must sum to a positive value.';
    return
end
if abs(probSum - 1) > 1e-6
    warning('ParseFlexibleVisualSequence:ProbRenorm', ...
        'Sequence probabilities sum to %.6f; renormalizing to 1.', probSum);
    probs = probs / probSum;
end

seqopts.flex_stim_definition = rawStim;
seqopts.flex_sequence_definition = rawSeq;
seqopts.seq_names = stimNames;
seqopts.angle = angles;
seqopts.contrast = contrasts;
seqopts.sequence_labels = seqLabels;
seqopts.sequence_token_cells = tokenCells;
seqopts.sequence_prob = probs(:).';
seqopts.num_sequence_types = numel(stimLists);
seqopts.random_slot_code = -1; % in parsed lists before run; routine resolves to 1..nStim before save

stim_type_cell = {};
trial_sequence_label_index = zeros(1, 0);
for s = 1:numel(stimLists)
    nRep = floor(probs(s) * N);
    for r = 1:nRep
        stim_type_cell{end+1} = stimLists{s}; %#ok<AGROW>
        trial_sequence_label_index(end+1) = s; %#ok<AGROW>
    end
end

if isempty(stim_type_cell)
    errMsg = 'No trials were allocated (check probabilities and number_trials).';
    return
end

ord = randperm(numel(stim_type_cell));
stim_type_cell = stim_type_cell(ord);
stim_type_cell = stim_type_cell(:);
trial_sequence_label_index = trial_sequence_label_index(ord);

padPat = stimLists{1};
while numel(stim_type_cell) < N
    stim_type_cell{end+1} = padPat; %#ok<AGROW>
    trial_sequence_label_index(end+1) = 1; %#ok<AGROW>
end
if numel(stim_type_cell) > N
    stim_type_cell = stim_type_cell(1:N);
    trial_sequence_label_index = trial_sequence_label_index(1:N);
end

seqopts.trial_sequence_label_index = trial_sequence_label_index(:).';
seqopts.stim_type_token_labels = labelsForTrials(stim_type_cell, stimNames);

end

%% --- stimulus table ---

function [stimNames, angles, contrasts, errMsg] = parseStimDefinition(raw)
errMsg = '';
stimNames = {};
angles = [];
contrasts = [];
lines = splitDefinitionLines(raw);
if isempty(lines)
    errMsg = 'flex_stim_definition is empty.';
    return
end

for i = 1:numel(lines)
    line = lines{i};
    parts = strtrim(strsplit(line, ','));
    if numel(parts) < 3
        errMsg = sprintf('Stimulus line %d must be name,angle_deg,contrast: "%s"', i, line);
        return
    end
    name = strtrim(parts{1});
    if isempty(name)
        errMsg = sprintf('Stimulus line %d has an empty name.', i);
        return
    end
    if strcmp(name, '$')
        errMsg = 'Stimulus name "$" is reserved for random slots in sequences.';
        return
    end
    if any(strcmp(stimNames, name))
        errMsg = sprintf('Duplicate stimulus name "%s".', name);
        return
    end
    ang = str2double(parts{2});
    ctr = str2double(parts{3});
    if ~isfinite(ang)
        errMsg = sprintf('Invalid angle on stimulus line %d: "%s".', i, parts{2});
        return
    end
    if ~isfinite(ctr) || ctr < 0
        errMsg = sprintf('Invalid contrast on stimulus line %d: "%s".', i, parts{3});
        return
    end
    stimNames{end+1} = name; %#ok<AGROW>
    angles(end+1) = ang; %#ok<AGROW>
    contrasts(end+1) = ctr; %#ok<AGROW>
end

angles = angles(:).';
contrasts = contrasts(:).';
end

%% --- sequence types ---

function [probs, stimLists, seqLabels, tokenCells, errMsg] = parseSequenceDefinition(raw, stimNames)
errMsg = '';
probs = [];
stimLists = {};
seqLabels = {};
tokenCells = {};
lines = splitDefinitionLines(raw);
if isempty(lines)
    errMsg = 'flex_sequence_definition is empty.';
    return
end

nameToIdx = containers.Map(stimNames, num2cell(1:numel(stimNames)));

for i = 1:numel(lines)
    line = lines{i};
    parts = splitCsvKeepEmpty(line);
    if numel(parts) < 2
        errMsg = sprintf('Sequence line %d needs probability and at least one slot: "%s"', i, line);
        return
    end
    p = str2double(strtrim(parts{1}));
    if ~isfinite(p) || p < 0
        errMsg = sprintf('Invalid probability on sequence line %d: "%s".', i, parts{1});
        return
    end
    slots = zeros(1, numel(parts) - 1);
    labelParts = cell(1, numel(parts) - 1);
    for j = 2:numel(parts)
        tok = strtrim(parts{j});
        if tokenIsBlank(tok)
            slots(j-1) = 0;
            labelParts{j-1} = ' ';
        elseif tokenIsRandom(tok)
            slots(j-1) = -1;
            labelParts{j-1} = '$';
        else
            if ~isKey(nameToIdx, tok)
                errMsg = sprintf('Unknown stimulus "%s" on sequence line %d.', tok, i);
                return
            end
            slots(j-1) = nameToIdx(tok);
            labelParts{j-1} = tok;
        end
    end
    probs(end+1) = p; %#ok<AGROW>
    stimLists{end+1} = slots; %#ok<AGROW>
    seqLabels{end+1} = strjoin(labelParts, '-'); %#ok<AGROW>
    tokenCells{end+1} = labelParts; %#ok<AGROW>
end
end

%% --- trial labels ---

function labels = labelsForTrials(stim_type_cell, stimNames)
labels = cell(numel(stim_type_cell), 1);
for i = 1:numel(stim_type_cell)
    labels{i} = SequenceIdxToLabelStr(stim_type_cell{i}, stimNames);
end
end

%% --- text / field helpers ---

function v = readScalarField(s, name, defaultVal)
if ~isstruct(s) || ~isfield(s, name) || isempty(s.(name))
    v = defaultVal;
    return
end
x = s.(name);
if isnumeric(x) && isscalar(x) && isfinite(x)
    v = double(x);
else
    v = defaultVal;
end
end

function s = flexCharField(cv, name, defaultVal)
if ~isstruct(cv) || ~isfield(cv, name) || isempty(cv.(name))
    s = defaultVal;
    return
end
s = normalizeCharRow(cv.(name));
end

function s = normalizeCharRow(x)
if isstring(x)
    if isscalar(x)
        s = char(x);
    else
        s = char(strjoin(x, newline));
    end
    return
end
if iscell(x)
    if isempty(x)
        s = '';
        return
    end
    if ischar(x{1})
        s = char(strjoin(cellfun(@char, x, 'UniformOutput', false), newline));
    else
        s = char(x{1});
    end
    return
end
if ischar(x)
    if size(x, 1) > 1
        s = char(strjoin(cellstr(x), newline));
    else
        s = x;
    end
    return
end
s = char(string(x));
end

function lines = splitDefinitionLines(raw)
raw = normalizeCharRow(raw);
raw = strrep(raw, sprintf('\r\n'), newline);
raw = strrep(raw, char(13), newline);
raw = strrep(raw, ';', newline);
chunks = strsplit(raw, newline);
lines = {};
for i = 1:numel(chunks)
    line = strtrim(chunks{i});
    if isempty(line)
        continue
    end
    hashPos = strfind(line, '#');
    if ~isempty(hashPos)
        line = strtrim(line(1:hashPos(1)-1));
    end
    if ~isempty(line)
        lines{end+1} = line; %#ok<AGROW>
    end
end
end

function parts = splitCsvKeepEmpty(line)
parts = {};
if isempty(line)
    return
end
start = 1;
n = numel(line);
for k = 1:n
    if line(k) == ','
        parts{end+1} = line(start:k-1); %#ok<AGROW>
        start = k + 1;
    end
end
parts{end+1} = line(start:n); %#ok<AGROW>
end

function tf = tokenIsBlank(tok)
tf = isempty(tok) || all(isspace(tok));
end

function tf = tokenIsRandom(tok)
tf = strcmp(strtrim(tok), '$');
end
