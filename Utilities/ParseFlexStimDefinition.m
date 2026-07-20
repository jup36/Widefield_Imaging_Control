function [stimopts, errMsg] = ParseFlexStimDefinition(cv)
% Parse flex_stim_definition text for routines that present single gratings.
% cv.flex_stim_definition: one stimulus per line: name,angle_deg,contrast
% Optional: flex_stim_duration (seconds)

errMsg = '';
stimopts = struct();

stimopts.flex_stim_duration = readScalarField(cv, 'flex_stim_duration', 0.5);
rawStim = flexCharField(cv, 'flex_stim_definition', '');

[stimNames, angles, contrasts, errMsg] = parseStimDefinition(rawStim);
if ~isempty(errMsg)
    return
end

stimopts.flex_stim_definition = rawStim;
stimopts.seq_names = stimNames;
stimopts.angle = angles;
stimopts.contrast = contrasts;

end

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
