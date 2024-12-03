function resting_state_with_behv_cameras_Nmin(app)
%auditory conditioning Imaging Routine Function
% Adapted from visual_sequence by Camden 2019
% Caroline Jahn & Junchol Park (April 2024)
%No white noise in this function

clearvars -except app;

%check if save directory exists
if ~exist(app.SaveDirectoryEditField.Value, 'dir')
    mkdir(app.SaveDirectoryEditField.Value)
else
    %confirm no log file already in the directory... to be extra safe,
    %adding timestamp to all filenames
    if exist([app.SaveDirectoryEditField.Value '%s_acquisitionlog.m'], 'file')~=0
        uialert(app.UIFigure,['Save dir already contains log file. Aquisition cancelled.\n',...
            'Select new save directory and try again'],'Overwrite Notice')
        return
    end
end

%% Initialize inputs/outputs
%create the port for communication with arduino
%If interacting with a program for the arduino
%The arduino program needs to be uploaded before running the MATLAB code
warning('Load arduino sketch runGng and press Enter to continue')
pause

dui = serialport("COM4", 9600);
configureTerminator(dui,"CR/LF"); % This specifies the terminator characters. "CR/LF" stands for Carriage Return (\r) and Line Feed (\n).
dui.UserData=struct("Data",[],"Count",1);
configureCallback(dui,"terminator",@readSerialData)
write(dui, "O", "char" ); %doesn't matter what we send, just not P or R 

% Use app.nidq_cmos instead of creating another nidq_cmos to prevent any
%  conflict between the two! app.nidq_cmos is created by the app as a part of the startup function to support pulse generation on the GUI 
% Create nidq_cmos for CMOS external pulse generation
% nidq_cmos = daq("ni");
% nidq_cmos.Rate = 3*1e5; % 300KHz
% ch_cmos = addoutput(nidq_cmos, "Dev1", 'ctr0', "PulseGeneration"); % PFI12 on BNC-2110
% ch_cmos.Frequency = 40; % 500 Hz %also hard coded in Camera script, not controlled here
% ch_cmos.DutyCycle = 0.7;

% Create nidq_faceCam for camera pulses
nidq_faceCam = daq("ni");
nidq_faceCam.Rate = 3*1e5; % 300KHz
ch_faceCam = addoutput(nidq_faceCam, "Dev1", 'ctr1', "PulseGeneration"); % PFI13 on BNC-2110
ch_faceCam.Frequency = 200; % 500 Hz %also hard coded in Camera script, not controlled here
ch_faceCam.DutyCycle = 0.5;

%% Initialize stim and outcomes
%Number of sequences
N = app.cur_routine_vals.number_sequence;

%% Initialize delays
%Add a little padding to make sure the CMOS camera is off and ready for the
%next trial + that behv camera had time to record
stimopts.tail_camera_frame_padding=10;

%calculate the full length of a block for the behvioral camera
stimopts.total_duration_sequence=app.cur_routine_vals.sequence_duration;% we have n stim and n rewards, so n * baseline+stim + n*baseline+post_reward
behav_camera_pulse_dur=ceil(stimopts.total_duration_sequence) + 10; %empiracally, seems to add 1s, maybe preload, writing etc...

%Behav_cam_off_padding=5; % This might not be necessary or minimized?
Cmd_to_pulse_delay=5;

%% Save
%save all stim that will be displayed
save_dir = fullfile([app.SaveDirectoryEditField.Value, filesep sprintf('%s_stimInfo.mat', datetime('now', 'Format', 'yyyy-MM-dd-HH-mm'))]);
save(save_dir, 'stimopts');
fprintf('Successsfully completed trials info recording\n')
trial_init_time = cell(N, 1);

%% RUN trials
%% Sequence of trials
for i = 1:N %N is the number of sequences, each made of 20 trials
    %Trigger CMOS camera start with a pulse
    start(app.nidq_cmos, "continuous");
    
    tic
    % Launch the python script that turns on the beh camera, and start generating camera pulses
    batchFilePath = "C:\Users\buschmanlab\Documents\pySpinCapture\run_faceCam_capture.bat"; % C:\Users\buschmanlab\Documents\pySpinCapture\cameraCaptureFaceCamPulse.py (video file location: 'E:\behvid')
    cmd = sprintf('"%s" %d %s %d && exit &', ...
        batchFilePath, behav_camera_pulse_dur, app.cur_routine_vals.mouse, i);
    
    system(cmd);
    WaitSecs(Cmd_to_pulse_delay); % Necessary to prevent pulse running before cameara launched
    start(nidq_faceCam, "Continuous"); % Run pulsing for behCam continuously, and stop it at the end of the trial
    fprintf('Begining Recording %d sequence...\n', i);
    trial_init_time{i} = datetime('now', 'Format', 'yyyy-MM-dd-HH-mm-ss');
    write(dui, "O", "char" );
    
    WaitSecs(stimopts.total_duration_sequence);
    
    toc
    stop(app.nidq_cmos); % turn off cmos pulses for this sequence
    %Padding to make sure camera is done and has time to save
    WaitSecs(stimopts.tail_camera_frame_padding);
    stop(nidq_faceCam); % turn off faceCam pulses for this sequence

    %trial ends here
    fprintf('Done with sequence %d\n',i);
end
stimopts.trial_init_time = trial_init_time;
save(save_dir, 'stimopts', '-append') % save trial initiation time
fprintf('Done Recording with session...\n');
clear nidq_faceCam dui

pause(10); %this MUST be a pause. WaitSecs does not trigger buffer fill

Screen('closeAll')

end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the callback function to read the serial data
function readSerialData(src,~)

data = readline(src); % Read the data from Arduino
src.UserData.Data(end+1)=str2double(data);
src.UserData.Count=src.UserData.Count+1;

outcome = str2double(char(data)); % Convert the received uint8 data to a number
if outcome==1
    fprintf('Reward\n'); % Display the received value
elseif outcome==2
    fprintf('Air Puff\n'); % Display the received value
elseif outcome==3
    fprintf('Manual reward\n'); % Display the received value
elseif outcome==4
    fprintf('Omission lick\n'); % Display the received value
end

end



