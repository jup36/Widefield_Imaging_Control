function continuous_camera_recording(app)
% Continuous imaging/behavior camera recording routine
% Records a single continuous block of data using the CMOS imaging pulses
% (via app.nidq_cmos) and the face camera controlled via pySpin.
%
% Duration of the recording (in seconds) is taken from:
%   app.cur_routine_vals.recording_duration
%
% This routine is modeled after resting_state_with_behv_cameras_Nmin.m,
% but simplified to run a single continuous block instead of multiple
% sequences.

clearvars -except app;

% Check if save directory exists
if ~exist(app.SaveDirectoryEditField.Value, 'dir')
    mkdir(app.SaveDirectoryEditField.Value)
else
    % Confirm no log file already in the directory... to be extra safe,
    % adding timestamp to all filenames
    if exist([app.SaveDirectoryEditField.Value '%s_acquisitionlog.m'], 'file')~=0
        uialert(app.UIFigure,['Save dir already contains log file. Aquisition cancelled.\n',...
            'Select new save directory and try again'],'Overwrite Notice');
        return
    end
end

% Let user choose where face-camera video files (MP4) will be saved
videoSaveDir = uigetdir([], 'Select folder where face camera videos will be saved');
if videoSaveDir == 0
    % User cancelled
    return
end

%% Initialize inputs/outputs
% Create the ports for communication with Arduino
% The Arduino programs need to be uploaded before running the MATLAB code
warning('Load arduino sketches and press Enter to continue')
pause

% Serial port operating all components except for water delivery
dui = serialport("COM5", 9600);
flush(dui); % Clear out any data in the serial buffer
configureTerminator(dui,"CR/LF");
dui.UserData = struct("Data",[],"Count",1);
configureCallback(dui,"terminator",@readSerialData);

% Serial port operating water delivery only
duiW = serialport("COM6", 9600);
flush(duiW);

write(dui,  "O", "char"); % doesn't matter what we send, just not P or R
write(duiW, "O", "char");

% Use app.nidq_cmos created by the app for CMOS external pulse generation
% (app.nidq_cmos should already be configured in the app startup)

% Create nidq_faceCam for camera pulses
nidq_faceCam = daq("ni");
nidq_faceCam.Rate = 3*1e5; % 300 KHz
ch_faceCam = addoutput(nidq_faceCam, "Dev1", 'ctr1', "PulseGeneration"); % PFI13 on BNC-2110
ch_faceCam.Frequency  = 200; % Hz, should match camera script expectations
ch_faceCam.DutyCycle  = 0.5;

%% Timing parameters
recording_duration_sec = app.cur_routine_vals.recording_duration;

% Whether to send CMOS pulses during the recording
if isfield(app.cur_routine_vals, 'use_cmos_pulses')
    use_cmos_pulses = logical(app.cur_routine_vals.use_cmos_pulses);
else
    % Default behavior if field is missing: do NOT send CMOS pulses
    use_cmos_pulses = false;
end

% Add a little padding to make sure the CMOS camera is off and ready for
% the next run + that behavior camera had time to record and save
stimopts.tail_camera_frame_padding = 10;

% Duration for which the behavioral camera should receive pulses
stimopts.total_duration_sequence = recording_duration_sec;
behav_camera_pulse_dur = ceil(stimopts.total_duration_sequence) + 10; % empirical buffer

Cmd_to_pulse_delay = 5; % delay to ensure camera script is running before pulses

%% Save basic info
stimopts.recording_duration_sec = recording_duration_sec;
save_dir = fullfile([app.SaveDirectoryEditField.Value, filesep sprintf('%s_stimInfo.mat', datetime('now', 'Format', 'yyyy-MM-dd-HH-mm'))]);
save(save_dir, 'stimopts');
fprintf('Successfully saved continuous recording info\n');

%% Run continuous recording
fprintf('Starting continuous imaging and face camera recording...\n');

% Trigger CMOS camera pulses (continuous) if enabled
if use_cmos_pulses
    start(app.nidq_cmos, "continuous");
end

% Launch the python script that turns on the face camera, and start
% generating camera pulses (pass video save folder as 4th argument)
batchFilePath = "C:\Users\buschmanlab\Documents\pySpinCapture\run_faceCam_capture_continous.bat";
cmd = sprintf('"%s" %d %s %d "%s" && exit &', ...
    batchFilePath, behav_camera_pulse_dur, app.cur_routine_vals.mouse, 1, videoSaveDir);
system(cmd);

WaitSecs(Cmd_to_pulse_delay); % prevent pulses from running before camera launched
start(nidq_faceCam, "Continuous"); % Run pulsing for faceCam continuously

trial_init_time = datetime('now', 'Format', 'yyyy-MM-dd-HH-mm-ss');

fprintf('Continuous recording started at %s\n', char(trial_init_time));

% Wait for the requested recording duration
WaitSecs(recording_duration_sec);

% Stop CMOS pulses and behavior camera pulses
if use_cmos_pulses
    stop(app.nidq_cmos);
end
WaitSecs(stimopts.tail_camera_frame_padding);
stop(nidq_faceCam);

fprintf('Continuous recording completed.\n');

% Append timing information
stimopts.trial_init_time = trial_init_time;
save(save_dir, 'stimopts', '-append');

% Clean up
clear nidq_faceCam dui duiW;

pause(10); % MUST be pause. WaitSecs does not trigger buffer fill

Screen('closeAll');

end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callback to read serial data from Arduino
function readSerialData(src, ~)

data = readline(src); % Read the data from Arduino
src.UserData.Data(end+1) = str2double(data);
src.UserData.Count = src.UserData.Count + 1;

outcome = str2double(char(data)); % Convert the received uint8 data to a number
if outcome == 1
    fprintf('Reward\n');
elseif outcome == 2
    fprintf('Air Puff\n');
elseif outcome == 3
    fprintf('Manual reward\n');
elseif outcome == 4
    fprintf('Omission lick\n');
end

end

