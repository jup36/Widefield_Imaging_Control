function deliver_random_visualstim_and_reward(app)
% Widefield recording with randomly timed single gratings and reward drops.
% Configure in the routine dialog:
%   flex_stim_definition — stimulus pool (name,angle_deg,contrast per line)
%   flex_stim_duration — seconds each grating is on
%   number_visual_trials, number_reward_trials — how many of each event type
%   visual_interval_mean_s / _std_s / _min_s — spacing between visual events
%   reward_interval_mean_s / _std_s / _min_s — spacing between reward events
%   post_reward_s — wait after sending reward command
%   reward_serial_port — e.g. COM6 (sends 'D' for one drop, lab DUI protocol)
%   recording_duration — total session length (seconds)

if ~exist(app.SaveDirectoryEditField.Value)
    mkdir(app.SaveDirectoryEditField.Value)
else
    if exist([app.SaveDirectoryEditField.Value '%s_acquisitionlog.m'])~=0
        uialert(app.UIFigure,['Save dir already contains log file. Aquisition cancelled.\n',...
            'Select new save directory and try again'],'Overwrite Notice')
        return
    end
end

[stimopts, parseErr] = ParseFlexStimDefinition(app.cur_routine_vals);
if ~isempty(parseErr)
    uialert(app.UIFigure, parseErr, 'Stimulus config');
    return
end

sessionDur = app.cur_routine_vals.recording_duration;
if ~isfinite(sessionDur) || sessionDur <= 0
    uialert(app.UIFigure, 'recording_duration must be positive.', 'Session config');
    return
end
nVisualCfg = round(readRoutineScalar(app.cur_routine_vals, 'number_visual_trials', 0));
nRewardCfg = round(readRoutineScalar(app.cur_routine_vals, 'number_reward_trials', 0));
if nVisualCfg < 1 && nRewardCfg < 1
    uialert(app.UIFigure, 'Set number_visual_trials and/or number_reward_trials to at least 1.', 'Session config');
    return
end

% Face camera (pySpin) — same pattern as ext_trigV1
nidq_faceCam = [];
videoSaveDir = uigetdir([], 'Select folder where face camera videos will be saved');
if videoSaveDir == 0
    return
end
nidq_faceCam = daq("ni");
nidq_faceCam.Rate = 3*1e5;
ch_faceCam = addoutput(nidq_faceCam, "Dev1", 'ctr1', "PulseGeneration");
ch_faceCam.Frequency  = 200;
ch_faceCam.DutyCycle  = 0.5;
stimopts.tail_camera_frame_padding = 10;
stimopts.total_duration_sequence = app.behav_cam_vals.duration_in_sec + app.behav_cam_vals.flank_duration + 10;
behav_camera_pulse_dur = ceil(stimopts.total_duration_sequence) + 10;
Cmd_to_pulse_delay = 5;

stimDur = stimopts.flex_stim_duration;
postReward = readRoutineScalar(app.cur_routine_vals, 'post_reward_s', 2);
trigSec = 5/round(app.cur_routine_vals.framerate);

[opts] = InitializeStaticGrating(stimopts.angle, stimopts.contrast);
nStim = numel(opts.gratingtex);

[events, eventSummary] = ScheduleRandomVisualRewardEvents(sessionDur, app.cur_routine_vals, nStim);
for k = 1:numel(events)
    if strcmp(events(k).type, 'visual')
        events(k).stim_name = stimopts.seq_names{events(k).stim_idx};
    else
        events(k).stim_name = '';
    end
end
stimopts.event_summary = eventSummary;
stimopts.events = events;

%% Reward serial (water DUI)
rewardPort = 'COM4';
if isfield(app.cur_routine_vals, 'reward_serial_port') && ~isempty(app.cur_routine_vals.reward_serial_port)
    rewardPort = strtrim(char(app.cur_routine_vals.reward_serial_port));
end
duiW = [];
stimopts.reward_duration = 0.02; %recalibrate!

% Release any leftover MATLAB serialport handles (common cause of "port in use")
try
    existing = serialportfind;
    if ~isempty(existing)
        delete(existing);
    end
catch
end

avail = {};
try
    avail = cellstr(serialportlist("available"));
catch
    try
        avail = cellstr(serialportlist);
    catch
    end
end

try
    duiW = serialport(rewardPort, 9600);
    configureTerminator(duiW, "CR/LF");
    duiW.UserData = struct("Data", [], "Count", 1);
    configureCallback(duiW, "terminator", @readSerialData);
    write(duiW, "O", "char"); % idle; not P or R
catch ME
    availStr = '(none listed)';
    if ~isempty(avail)
        availStr = strjoin(avail, ', ');
    end
    uialert(app.UIFigure, sprintf([ ...
        'Could not open reward port %s.\n%s\n\n', ...
        'Available ports: %s\n', ...
        'In Edit Routine set Reward serial port to the correct COMx,\n', ...
        'or run: clear all  (releases stuck serial handles).'], ...
        rewardPort, ME.message, availStr), 'Serial');
    return
end

%% Analog inputs / trigger output / log
a = daq.createSession('ni');
channels = [app.cur_routine_vals.expose_out_chan,...
    app.cur_routine_vals.frame_readout_chan,...
    app.cur_routine_vals.photodiode_chan,...
    app.cur_routine_vals.trigger_ready_chan];
for chan = 1:numel(channels)
    c = channels(chan);
    ch = addAnalogInputChannel(a, 'Dev1', c, 'Voltage');
    if c ~= app.cur_routine_vals.photodiode_chan
        ch.TerminalConfig = 'SingleEnded';
    end
end
a.Rate = app.cur_routine_vals.analog_in_rate;

s = daq.createSession('ni');
s.Rate = app.cur_routine_vals.analog_out_rate;
s.addAnalogOutputChannel('Dev1', sprintf('ao%d', app.cur_routine_vals.trigger_out_chan), 'Voltage');

log_fn = [app.SaveDirectoryEditField.Value filesep sprintf('%s_acquisitionlog.m', datestr(now, 'mm-dd-yyyy-HH-MM'))];
logfile = fopen(log_fn, 'w');
saveStamp = datestr(now, 'mm-dd-yyyy-HH-MM');
stimInfoPath = [app.SaveDirectoryEditField.Value, filesep sprintf('%s_stimInfo.mat', saveStamp)];
recParamsPath = [app.SaveDirectoryEditField.Value, filesep sprintf('%s_recordingparameters.mat', saveStamp)];
recordingparameters = {app.cur_routine_vals, app.behav_cam_vals};

KbName('UnifyKeyNames');
RestrictKeysForKbCheck(KbName('ESCAPE'));
escKeyCleanup = onCleanup(@() RestrictKeysForKbCheck([]));

lh = addlistener(a, 'DataAvailable', @(src, event) LogAquiredData(src, event, logfile));
a.IsContinuous = true;
a.startBackground;

fprintf('\nScheduled %d visual and %d reward events over %.1f s (configured %d / %d trials)\n', ...
    eventSummary.n_visual, eventSummary.n_reward, sessionDur, nVisualCfg, nRewardCfg);

try
    start(app.nidq_cmos, "continuous");

    filename = CreateVideoRecordingScript([app.rootdir filesep 'Behavioral_MultiCam' filesep],...
        [app.SaveDirectoryEditField.Value filesep], app.behav_cam_vals, 'duration_in_sec',...
        (app.behav_cam_vals.duration_in_sec + app.behav_cam_vals.flank_duration + 10));
    cmd = sprintf('python "%s" && exit &', filename);
    system(cmd)

    batchFilePath = "C:\Users\buschmanlab\Documents\pySpinCapture\run_faceCam_capture_continous.bat";
    mouse_id = char(app.cur_routine_vals.mouse);
    cmd_face = sprintf('"%s" %d %s %d "%s" && exit &', ...
        batchFilePath, behav_camera_pulse_dur, mouse_id, 1, videoSaveDir);
    system(cmd_face);
    WaitSecs(Cmd_to_pulse_delay);
    start(nidq_faceCam, "Continuous");
    fprintf('\nBegining Recording');

    userAborted = false;
    sessionT0 = GetSecs;

    for k = 1:numel(events)
        waitS = events(k).time_s - (GetSecs - sessionT0);
        if waitS > 0
            if WaitSecsOrEsc(waitS)
                userAborted = true;
                break
            end
        end

        if strcmp(events(k).type, 'visual')
            fprintf('\nEvent %d/%d: visual %s at t=%.2f s\n', k, numel(events), events(k).stim_name, events(k).time_s);
            outputSingleScan(s, 4);
            if WaitSecsOrEsc(trigSec)
                userAborted = true; break
            end
            outputSingleScan(s, 0);
            WaitSecsOrEsc(0.02);
            if showGrating(opts, events(k).stim_idx, stimDur, 0, s)
                userAborted = true; break
            end
        else
            fprintf('\nEvent %d/%d: reward at t=%.2f s\n', k, numel(events), events(k).time_s);
            write(duiW, "D", "char");
            WaitSecs(stimopts.reward_duration);
            write(duiW, "O", "char"); % clear reward mode (must be same port as R)

            if WaitSecsOrEsc(postReward)
                userAborted = true; break
            end
        end
    end

    if ~userAborted
        while (GetSecs - sessionT0) < sessionDur
            rem = sessionDur - (GetSecs - sessionT0);
            if WaitSecsOrEsc(min(rem, 0.5))
                userAborted = true;
                break
            end
        end
    end

    if userAborted
        fprintf('\nRecording stopped by user (ESC).\n');
    end

    fprintf('\nDone Recording... Filling buffer and wrapping up...');
    WaitSecs(stimopts.tail_camera_frame_padding);
    try
        stop(nidq_faceCam);
    catch
    end
    WaitSecs(app.behav_cam_vals.flank_duration);

    save(stimInfoPath, 'stimopts', 'events', 'eventSummary');
    save(recParamsPath, 'recordingparameters');

    pause(10);
    try
        a.stop;
    catch
    end
    if logfile > 0
        fclose(logfile);
    end
    delete(lh);

    fprintf('\nSuccesssfully completed recording. Wrapping up...\n');
    Screen('closeAll')

    try
        stop(app.nidq_cmos);
    catch
    end

catch ME
    if exist('logfile', 'var') && logfile > 0
        try
            fclose(logfile);
        catch
        end
    end
    if exist('lh', 'var')
        try
            delete(lh);
        catch
        end
    end
    if exist('nidq_faceCam', 'var') && ~isempty(nidq_faceCam)
        try
            stop(nidq_faceCam);
        catch
        end
    end
    try
        stop(app.nidq_cmos);
    catch
    end
    if exist('stimInfoPath', 'var')
        try
            save(stimInfoPath, 'stimopts', 'events', 'eventSummary');
            save(recParamsPath, 'recordingparameters');
        catch
        end
    end
    fprintf(2, 'Error in deliver_random_visualstim_and_reward: %s\n', ME.message);
end

if ~isempty(duiW) && isvalid(duiW)
    clear duiW;
end

end

function v = readRoutineScalar(s, name, defaultVal)
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
