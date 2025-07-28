function auditory_conditioning_operant_day0(app)
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
% Analog Inputs
%Create nidq object (from ow on we only use it for the audio but we kept
%the other channels just in case)
nidq = daq("ni");
nidq.Rate = 3*1e5; % can't be at max, reducing to min 2*max freq of auditory stim

nidq_out_list = "audio";
addoutput(nidq, "Dev1", "ao0", "Voltage"); % audio

%create the port for communication with arduino
%If interacting with a program for the arduino
%The arduino program needs to be uploaded before running the MATLAB code
warning('Load arduino sketch runGng and press Enter to continue')
pause

dui = serialport("COM5", 9600); % operates all components except for water delivery (change made on 12/12/24 to troubleshoot the hardware issue)
flush(dui); % Clear out any data in the serial buffer
configureTerminator(dui,"CR/LF"); % This specifies the terminator characters. "CR/LF" stands for Carriage Return (\r) and Line Feed (\n).
dui.UserData=struct("Data",[],"Count",1);
configureCallback(dui,"terminator",@readSerialData)

duiW = serialport("COM6", 9600); % operates water delivery only either by lick or switch
flush(duiW); 

write(dui, "O", "char" ); %doesn't matter what we send, just not P or R 
write(duiW, "O", "char" );

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
stimopts.NTrials_per_sequence= app.cur_routine_vals.NTrials_per_sequence; %10; % Needs to figure out how many trials can be run in 2 min (the target duration of each sequence)

%Initialize audiotry Stimuli
stimopts.tone_table=[1000, 14000, 80000; 5000, 16000, 40000]; %middle tone: 2794, 18000, 60000; 3 tones with mixed of audible and US freq (more likely to activate dorsal auditory cortex)
stimopts.amplitude=1; %10V output for speaker

%Build sequences.
stimopts.stim_id = [1 2];
stimopts.positive_stim = 1; % might need to counterbalance across mice
stimopts.negative_stim = 2; % might need to counterbalance
% stimopts.neutral_stim = 2; % might need to counterbalance
stimopts.stim_prob(stimopts.positive_stim) = 0.8;%80 ; %positive stim
stimopts.stim_prob(stimopts.negative_stim) = 0.2;%20 ; %negative stim
% stimopts.stim_prob(stimopts.neutral_stim) = 0; %neutral stim

%Attribute outcome
stimopts.proba_positive_stim = [1 0 0]; % [reward omission punishment]
stimopts.proba_negative_stim = [0 1 0]; % [reward omission punishment]

stim_sequence = [];
for i = 1:numel(stimopts.stim_prob)
    stim_sequence = cat(1,stim_sequence,repmat(stimopts.stim_id(i),floor(stimopts.stim_prob(i)*stimopts.NTrials_per_sequence),1));
end

%now create N sequences that are shuffles of stim_sequence
stim_type = [];
for i=1:N
    stim_type(end+1:end+length(stim_sequence),1)=stim_sequence(randperm(size(stim_sequence,1),size(stim_sequence,1)),:);
end

%record in stimopts struct
stimopts.stim_type=stim_type;

%positve stim
if sum(stim_type==stimopts.positive_stim)>0
    outcome_positive_stim = add_rpo(stimopts.proba_positive_stim, sum(stim_type==stimopts.positive_stim));
else
    outcome_positive_stim = [];
end

%negative stim
if sum(stim_type==stimopts.negative_stim)>0
    outcome_negative_stim = add_rpo(stimopts.proba_negative_stim, sum(stim_type==stimopts.negative_stim));
else
    outcome_negative_stim = [];
end

%Attribute to stim type (match the randomization)
stimopts = organize_rp_trials_pos_neg_stims(stimopts, stim_type, outcome_positive_stim, outcome_negative_stim);

if exist('outcome_negative_stim', 'var')
    stimopts.outcome_negative_stim = outcome_negative_stim;
end

if exist('outcome_positive_stim', 'var')
    stimopts.outcome_positive_stim = outcome_positive_stim;
end

%Attribute to stim type (match the randomization)
stimopts = organize_rp_trials_pos_neg_stims(stimopts, stim_type, outcome_positive_stim, outcome_negative_stim);

%record in stimopts struct
stimopts.stim_type=stim_type;

%% Initialize delays
%Baseline delay (stim delay, jittered)
stimopts.min_stim_delay=1; %2
stimopts.max_stim_delay=2; %3
stimopts.stim_delay_step=1/round(app.cur_routine_vals.framerate/2);

stimopts.stim_delay_list = stimopts.min_stim_delay:stimopts.stim_delay_step:stimopts.max_stim_delay;
%draw from uniform ditribution
stimopts.stim_delay_index=randi(length(stimopts.stim_delay_list),N*stimopts.NTrials_per_sequence);
%shuffle
stimopts.stim_delay_index=stimopts.stim_delay_index(randperm(length(stimopts.stim_delay_index)));
%store delay for each trial
stimopts.stim_delay=stimopts.stim_delay_list(stimopts.stim_delay_index);

%stim duration (fixed)
stimopts.stim_duration=2; %target duration

%reward period (fixed)
stimopts.reward_duration=3; %actually set directly on the arduino, it is the maximum amount of time that the spout would be out (if the mouse licks on a go trial)

%Delay post outcome
%We want to compensate to make sure all trials have the same duration (because of the fixed number of frames)
stimopts.post_reward=1; %1; originally 1 but now is halved for consistency after introducing 500ms outcome delay
stimopts.post_stim_delay_padding=stimopts.max_stim_delay-stimopts.stim_delay; %make up for time not given to baseline

%Add a little padding to make sure the CMOS camera is off 
% and ready for the
%next trial + that behv camera had time to record
stimopts.tail_camera_frame_padding=15; % 10;

%use all the delays to calculate the full length of a block for the behvioral
%camera
stimopts.total_duration_sequence=stimopts.NTrials_per_sequence*...
    (stimopts.max_stim_delay+stimopts.stim_duration+stimopts.reward_duration+stimopts.post_reward);% we have n stim and n rewards, so n * baseline+stim + n*baseline+post_reward
behav_camera_pulse_dur=ceil(stimopts.total_duration_sequence) + 10; %empiracally, seems to add 1s, maybe preload, writing etc...

%Behav_cam_off_padding=5; % This might not be necessary or minimized?
Cmd_to_pulse_delay=5;

%% Create the stim
%let's create the signal out in advance to see if it removes additional
%delays
signal_out_1=digital_out_stim_only(nidq.Rate, nidq_out_list, stimopts.stim_duration, stimopts.tone_table(1,:), stimopts.amplitude);
signal_out_2=digital_out_stim_only(nidq.Rate, nidq_out_list, stimopts.stim_duration, stimopts.tone_table(2,:), stimopts.amplitude);

%% Save
%save all stim that will be displayed
save_dir = fullfile([app.SaveDirectoryEditField.Value, filesep sprintf('%s_stimInfo.mat', datetime('now', 'Format', 'yyyy-MM-dd-HH-mm'))]);
save(save_dir, 'stimopts');
fprintf('Successsfully completed trials info recording\n')
trial_init_time = cell(N, 1);

%% RUN trials
%% Sequence of trials
% time elapsed for each sequence is approximately 97s
for i = 1:N %N is the number of sequences, each made of 10 trials
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
    write(dui, "S", "char" );
    write(duiW, "S", "char" );

    for j=1:stimopts.NTrials_per_sequence
        index=(i-1)*stimopts.NTrials_per_sequence + j; %index in the stim_type vector

        %% Start the nidq that will run for the duration of the trial
        %tic;

        %trial starts here
        fprintf('Staring trial %d out of %d\n',index,N*stimopts.NTrials_per_sequence);
        WaitSecs(stimopts.stim_delay(index));

        %deliver stimulus (1s fixed)
        if stimopts.stim_type(index)==1
            signal_out=signal_out_1;
        elseif stimopts.stim_type(index)==2
            signal_out=signal_out_2;
        end

        %preload(nidq, signal_out)
        %start(nidq,"RepeatOutput") % Play the tone
        WaitSecs(stimopts.stim_duration);
        %stop(nidq); % Finish the tone

        %New code when interacting with the program that controls the arduino
        %Outcome delivery
        if stimopts.rewarded_stim(index)
            write(dui, "U", "char" ); % write U instead of R; U delivers a free reward while also rewarding licks
            write(duiW, "U", "char" ); % duplicate
            fprintf('Rewarded trial\n');
            WaitSecs(stimopts.reward_duration);
            WaitSecs(stimopts.post_reward+stimopts.post_stim_delay_padding(index));
            write(dui, "I", "char" ); % to end the trial with keeping the spout in 
            write(duiW, "I", "char" ); % duplicate
        elseif stimopts.punished_stim(index)
            write(dui, "P", "char" );
            write(duiW, "P", "char" );
            fprintf('Punished trial\n');
            WaitSecs(stimopts.reward_duration);
            WaitSecs(stimopts.post_reward+stimopts.post_stim_delay_padding(index));
            write(dui, "I", "char" ); % to end the trial with keeping the spout in 
            write(duiW, "I", "char" ); 
        else
            write(dui, "N", "char" );
            write(duiW, "N", "char" );
            fprintf('Omission trial\n');
            WaitSecs(stimopts.reward_duration);
            WaitSecs(stimopts.post_reward+stimopts.post_stim_delay_padding(index));
        end
        % Allow MATLAB to process events like serial data callbacks
        drawnow; % This is critical for serial callback function readSerialData to work properly
    end
    WaitSecs(1.2) % 12/10/24 modified
    toc
    stop(app.nidq_cmos); %
    % turn off cmos pulses for this sequence
    %Padding to make sure camera is done and has time to save
    WaitSecs(stimopts.tail_camera_frame_padding-1.2);
    stop(nidq_faceCam); % turn off faceCam pulses for this sequence

    %trial ends here
    fprintf('Done with sequence %d\n',i);
end
stimopts.trial_init_time = trial_init_time;
save(save_dir, 'stimopts', '-append') % save trial initiation time
fprintf('Done Recording with session...\n');

rewards=sum(dui.UserData.Data==1);
airpuffs=sum(dui.UserData.Data==2);
omissions=sum(dui.UserData.Data==4);
manual_rewards=sum(dui.UserData.Data==3);

stimopts.rewards=rewards;
stimopts.airpuffs=airpuffs;
stimopts.omissions=omissions;

stimopts.dui=dui;

save(save_dir, 'stimopts', '-append') % save trial initiation time

fprintf('\nMouse received %d rewards, %d air puffs and %d licks on omission\n',rewards,airpuffs,omissions)
fprintf('\nGave %d manual rewards\n',manual_rewards)

pause(10); %this MUST be a pause. WaitSecs does not trigger buffer fill

Screen('closeAll')

end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the callback function to read the serial data
% function readSerialData(src,~)
% 
% data = readline(src); % Read the data from Arduino
% src.UserData.Data(end+1)=str2double(data);
% src.UserData.Count=src.UserData.Count+1;
% 
% outcome = str2double(char(data)); % Convert the received uint8 data to a number
% if outcome==1
%     fprintf('Reward\n'); % Display the received value
% elseif outcome==2
%     fprintf('Air Puff\n'); % Display the received value
% elseif outcome==3
%     fprintf('Manual reward\n'); % Display the received value
% elseif outcome==4
%     fprintf('Omission lick\n'); % Display the received value
% end
% 
% end

function readSerialData(src, ~)

    % Check if there is data available to read
    while src.NumBytesAvailable > 0
        % Read one line of data
        data = readline(src); 
        outcome = str2double(data);  % Convert the string to a number

        % Add to UserData for counting if needed
        src.UserData.Data(end+1) = outcome;
        src.UserData.Count = src.UserData.Count + 1;

        % Print the message immediately based on the outcome received
        switch outcome
            case 1
                fprintf('Reward\n');
            case 2
                fprintf('Air Puff\n');
            case 3
                fprintf('Manual reward\n');
            case 4
                fprintf('Omission lick\n');
            otherwise
                fprintf('Unknown outcome: %d\n', outcome);
        end
    end
end


