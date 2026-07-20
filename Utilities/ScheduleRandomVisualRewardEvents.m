function [events, summary] = ScheduleRandomVisualRewardEvents(sessionDur, cv, nStim)
% Build a merged event list for random visual stimuli and reward drops.
%
% cv fields:
%   number_visual_trials, number_reward_trials — exact event counts
%   visual_interval_mean_s, visual_interval_std_s, visual_interval_min_s
%   reward_interval_mean_s, reward_interval_std_s, reward_interval_min_s
%   recording_duration (sessionDur arg) — events are scaled to fit if needed
%
% events(k): .time_s, .type ('visual'|'reward'), .stim_idx (visual only, 1..nStim)

if nargin < 3 || isempty(nStim) || nStim < 1
    nStim = 1;
end

nVisual = round(readField(cv, 'number_visual_trials', 0));
nReward = round(readField(cv, 'number_reward_trials', 0));

visualTimes = drawEventTimes(sessionDur, cv, 'visual', nVisual);
rewardTimes = drawEventTimes(sessionDur, cv, 'reward', nReward);

events = struct('time_s', {}, 'type', {}, 'stim_idx', {}, 'stim_name', {});
for t = visualTimes
    idx = randi(nStim);
    events(end+1) = struct('time_s', t, 'type', 'visual', 'stim_idx', idx, 'stim_name', ''); %#ok<AGROW>
end
for t = rewardTimes
    events(end+1) = struct('time_s', t, 'type', 'reward', 'stim_idx', NaN, 'stim_name', ''); %#ok<AGROW>
end

if isempty(events)
    summary = struct('n_visual', 0, 'n_reward', 0, 'session_dur_s', sessionDur, ...
        'number_visual_trials', nVisual, 'number_reward_trials', nReward);
    return
end

[~, ord] = sort([events.time_s]);
events = events(ord);

summary = struct();
summary.n_visual = numel(visualTimes);
summary.n_reward = numel(rewardTimes);
summary.number_visual_trials = nVisual;
summary.number_reward_trials = nReward;
summary.session_dur_s = sessionDur;
summary.visual_interval_mean_s = readField(cv, 'visual_interval_mean_s', 30);
summary.reward_interval_mean_s = readField(cv, 'reward_interval_mean_s', 45);
if ~isempty(visualTimes) && numel(visualTimes) > 1
    summary.visual_interval_empirical_mean_s = mean(diff(visualTimes));
end
if ~isempty(rewardTimes) && numel(rewardTimes) > 1
    summary.reward_interval_empirical_mean_s = mean(diff(rewardTimes));
end

end

function times = drawEventTimes(sessionDur, cv, kind, nEvents)
times = [];
if nEvents <= 0
    return
end

prefix = [kind '_interval_'];
meanS = readField(cv, [prefix 'mean_s'], defaultMean(kind));
stdS = max(0, readField(cv, [prefix 'std_s'], defaultStd(kind)));
minS = max(0.05, readField(cv, [prefix 'min_s'], defaultMin(kind)));

t = 0;
times = zeros(1, nEvents);
for k = 1:nEvents
    dt = max(minS, meanS + stdS * randn);
    t = t + dt;
    times(k) = t;
end

if sessionDur > 0 && times(end) > sessionDur
    times = times * (sessionDur * 0.98) / times(end);
end
times = times(:).';
end

function v = defaultMean(kind)
if strcmp(kind, 'visual')
    v = 30;
else
    v = 45;
end
end

function v = defaultStd(kind)
if strcmp(kind, 'visual')
    v = 10;
else
    v = 15;
end
end

function v = defaultMin(kind)
if strcmp(kind, 'visual')
    v = 5;
else
    v = 10;
end
end

function v = readField(cv, name, defaultVal)
if ~isstruct(cv) || ~isfield(cv, name) || isempty(cv.(name))
    v = defaultVal;
    return
end
x = cv.(name);
if isnumeric(x) && isscalar(x) && isfinite(x)
    v = double(x);
else
    v = defaultVal;
end
end
