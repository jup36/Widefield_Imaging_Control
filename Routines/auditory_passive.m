function auditory_passive(app)
%auditory stim oresneted only (no reward)
% Adapted from visual_sequence by Camden 2019
% Caroline Jahn & Junchol Park (August 2023)
%No white noise in this function

%Reward and two auditory stimuli, one common (80%) and one uncommon (20%),
%are randomly delivered

clearvars -except app;

%Can't synch screens, but no proeblem because we're using the photodiode anyway
Screen('Preference','SkipSyncTests', 1);
% 
%check if save directory exists
if ~exist(app.SaveDirectoryEditField.Value)
    mkdir(app.SaveDirectoryEditField.Value)
else
    %confirm no log file already in the directory... to be extra safe,
    %adding timestamp to all filenames
    if exist([app.SaveDirectoryEditField.Value '%s_acquisitionlog.m'])~=0
        uialert(app.UIFigure,['Save dir already contains log file. Aquisition cancelled.\n',...
            'Select new save directory and try again'],'Overwrite Notice')
        return
    end
end

%% Initialize inputs/outputs and log file
% Analog Inputs
%Create nidq object (from ow on we only use it for the audio but we kept
%the other channels just in case)
nidq = daq("ni");
nidq.Rate = 3*1e5; % can't be at max, reducing to min 2*max freq of auditory stim

nidq_out_list = ["audio", "airpuff", "water", "trigger"];
addoutput(nidq, "Dev27", "ao0", "Voltage"); % audio
addoutput(nidq, "Dev27", "Port0/Line8", "Digital"); % airpuff
addoutput(nidq, "Dev27", "Port0/Line9", "Digital"); % water
addoutput(nidq, "Dev27", "ao1", "Voltage"); % trigger

%create the port for communication with arduino
%If interacting with a program for the arduino
%The arduino program needs to be uploaded before running the MATLAB code

warning('Load arduino sketch deliver_water and press Enter to continue')
pause

dui = serialport("COM4", 9600);
configureTerminator(dui,"CR/LF");
dui.UserData=struct("Data",[],"Count",1);
configureCallback(dui,"terminator",@readSerialData)
write(dui, "O", "char" ); %doesn't matter what we send, just not P or R

%Create nidq for camera pulses
nidq_vid = daq("ni");
nidq_vid.Rate = 3*1e5; % 300KHz
ch_pulse = addoutput(nidq_vid, "Dev27", 'ctr0', "PulseGeneration"); % add counter for PulseGeneration
ch_pulse.Frequency = 200; % 500 Hz %also hard coded in Camera script, not controlled here
ch_pulse.DutyCycle = 0.25;

%Number of trials
N = app.cur_routine_vals.number_trials;

% NO BACKGROUND, TURN SCREEN OFF 
% %Initialize Stimuli
% stimopts.angle = [45,135];
% stimopts.contrast = [0.4,0.4]; %rationale for choice of 40% contrast from https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6623377/
% [opts] = InitializeStaticGrating_blue(stimopts.angle,stimopts.contrast); %just added _blue

%Initialize audiotry Stimuli
stimopts.tone_table=[2093, 14000, 80000; 3951, 16000, 40000]; %middle tone: 2794, 18000, 60000; 3 tones with mixed of audible and US freq (more likely to activate dorsal auditory cortex)
stimopts.amplitude=0.3; %10V output for speaker

%Baseline delay (stim delay)
stimopts.baseline=2; %2
%stim duration (fixed)
stimopts.stim_duration=2; %target duration
%post reward
stimopts.post_reward=3; %2

%Add a little padding to make sure the CMOS camera is off and ready for the
%next trial + that behv camera had time to record
stimopts.tail_camera_frame_padding=5;

%Build sequences. Reccomend 500 trials of 190 frames (imaging)
stimopts.stim_id = [1 2 3];
stimopts.common_stim = 1; % might need to counterbalance across mice
stimopts.uncommon_stim = 2; % might need to counterbalance
stimopts.stim_prob(stimopts.common_stim) = 0.8;%75 ; %positive stim
stimopts.stim_prob(stimopts.uncommon_stim) = 0.2; %neutral stim

stimopts.sequence_length=20;

stim_sequence = [];
for i = 1:numel(stimopts.stim_prob)
    stim_sequence = cat(1,stim_sequence,repmat(stimopts.stim_id(i),floor(stimopts.stim_prob(i)*stimopts.sequence_length),1));
end
% stim_sequence(end+1:end+stimopts.sequence_length)=3; %add 3 for reward
% only (no stim) here we do not have reward so do not add a stim id 3 as in
% the auditor_reward_passive

%now create N sequences that are shuffles of stim_sequence
stim_type = [];
for i=1:N
    stim_type(end+1:end+length(stim_sequence))=stim_sequence(randperm(size(stim_sequence,1),size(stim_sequence,1)),:);
end

%record in stimopts struct
stimopts.stim_type=stim_type;

%use all the delays to calculate the full length of a block for the behvioral
%camera
% total_duration_sequence=stimopts.sequence_length*(stimopts.baseline*2+stimopts.stim_duration+stimopts.post_reward);% we have n stim and n rewards, so n * baseline+stim + n*baseline+post_reward
total_duration_sequence=stimopts.sequence_length*(stimopts.baseline+stimopts.stim_duration);% we have n stim so n * baseline+stim 

behav_camera_pulse_dur=90; %ceil(total_duration_sequence)+2; %add 2 s just to be sure to capture everything

%Behav_cam_off_padding=5; % This might not be necessary or minimized?
Cmd_to_pulse_delay=5;

%save all stim that will be displayed
save_dir = fullfile([app.SaveDirectoryEditField.Value, filesep sprintf('%s_stimInfo.mat', datetime('now', 'Format', 'yyyy-MM-dd-HH-mm'))]);
save(save_dir, 'stimopts');
fprintf('Successsfully completed trials info recording\n')
trial_init_time = cell(N, 1);

%% RUN trials
%% Sequence of trials
for i = 1:N %N is the number of sequences, each made of 10 rewards and 10 stim
    %Trigger CMOS camera start with a pulse
    digital_out(nidq, nidq_out_list, "trigger", 5/round(app.cur_routine_vals.framerate), 4)
   
    tic

    % Launch the python script that turns on the beh camera, and start generating camera pulses
    cmd = sprintf('python %s %d %s %d && exit &', 'C:\Users\mouse1\Documents\GitHub\pySpinCapture\cameraCapture2camsPulse.py', behav_camera_pulse_dur, app.cur_routine_vals.mouse, i);
    system(cmd);
    WaitSecs(Cmd_to_pulse_delay); % Necessary to prevent pulse running before cameara launched
    start(nidq_vid, "Continuous"); % Run pulsing for behCam continuously, and stop it at the end of the trial
    fprintf('Begining Recording %d trial...\n', i);


    %Baseline: stim_delay, random between 2 and 4s to prevent mice
    %from knowing when the stim is coming based on LED but spaced by 2
    %frames to make sure we're always at the start of the LED onset

    trial_init_time{i} = datetime('now', 'Format', 'yyyy-MM-dd-HH-mm-ss');

    for j=1:stimopts.sequence_length
        index=(i-1)*stimopts.sequence_length + j; %index in the stim_type vector
        %% Start the nidq that will run for the duration of the trial
        %tic;

        %trial starts here
        WaitSecs(stimopts.baseline);
%         if stimopts.stim_type(index)<3 %if it's a stim we show
            %deliver stimulus (1s fixed)
            signal_out=digital_out_stim_only(nidq.Rate, nidq_out_list, stimopts.stim_duration, stimopts.tone_table(stimopts.stim_type(index),:), stimopts.amplitude);
            preload(nidq, signal_out)
            start(nidq,"RepeatOutput")
            WaitSecs(stimopts.stim_duration);
            stop(nidq);
%         elseif stimopts.stim_type(index)==3 %reward
%             write(dui, "D", "char" ); %deliver a drop
%             WaitSecs(stimopts.post_reward);
%         end

    end
    toc
    %Padding to make sure camera is done
    WaitSecs(stimopts.tail_camera_frame_padding);
    stop(nidq_vid);

    %trial ends here
    fprintf('Done with trial %d\n',i);

end
stimopts.trial_init_time = trial_init_time;
save(save_dir, 'stimopts', '-append') % save trial initiation time
fprintf('Done Recording with session...\n');

rewards=sum(dui.UserData.Data==1);
airpuffs=sum(dui.UserData.Data==2);

stimopts.rewards=rewards;
stimopts.airpuffs=airpuffs;

stimopts.dui=dui;

save(save_dir, 'stimopts', '-append') % save trial initiation time

fprintf('\nMouse received %d rewards and %d air puffs\n',rewards,airpuffs)

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
end

end



