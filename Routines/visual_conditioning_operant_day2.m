function visual_conditioning_operant_day2(app)
%Visualconditioning Imaging Routine Function
% Adapted from visual_sequence by Camden 2019
% Caroline Jahn & Junchol Park (March 2023)

clearvars -except app;

%Can't synch screens, but no proeblem because we're using the photodiode anyway
Screen('Preference','SkipSyncTests', 1);

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

warning('Load arduino sketch lick_switch_water_air_MR_50ms and press Enter to continue')
pause

dui = serialport("COM4", 9600);
configureTerminator(dui,"CR/LF");
dui.UserData=struct("Data",[],"Count",1);
configureCallback(dui,"terminator",@readSerialData)
%write(dui, "O", "char" ); %doesn't matter what we send, just not P or R

%Create nidq for camera pulses
nidq_vid = daq("ni");
nidq_vid.Rate = 3*1e5; % 300KHz
ch_pulse = addoutput(nidq_vid, "Dev27", 'ctr0', "PulseGeneration"); % add counter for PulseGeneration
ch_pulse.Frequency = 200; % 500 Hz %also hard coded in Camera script, not controlled here
ch_pulse.DutyCycle = 0.25;

%Number of trials
N = app.cur_routine_vals.number_trials;

%Initialize Stimuli
stimopts.angle = [0,45,90]; %drifting doesn't work with 45 degrees yet
stimopts.contrast = [0.4,0.4,0.4]; %rationale for choice of 40% contrast from https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6623377/
% [opts] = InitializeStaticGrating_blue(stimopts.angle,stimopts.contrast);
[opts] = InitializeDriftingGrating_blue(stimopts.angle,stimopts.contrast);
opts.DriftCyclesPerSecond=1;

%Baseline delay (stim delay, jittered)
stimopts.min_stim_delay=2; %2
stimopts.max_stim_delay=3; %3
stimopts.stim_delay_step=1/round(app.cur_routine_vals.framerate/2);
stimopts.stim_delay_list = stimopts.min_stim_delay:stimopts.stim_delay_step:stimopts.max_stim_delay;

%draw from uniform ditribution
stimopts.stim_delay_index=randi(length(stimopts.stim_delay_list),N);
%shuffle
stimopts.stim_delay_index=stimopts.stim_delay_index(randperm(length(stimopts.stim_delay_index)));
%store delay for each trial
stimopts.stim_delay=stimopts.stim_delay_list(stimopts.stim_delay_index);

%stim duration (fixed)
stimopts.stim_duration=5; %5; %2 %target duration

%Reward and air puff duration
%This is hard coded in the arduino program and not controlled by MATLAB
stimopts.reward_duration=0.02; %recalibrate!
stimopts.air_puff_duration=0.02;
stimopts.nothing_duration=max(stimopts.reward_duration, stimopts.air_puff_duration);

%Dead time durinf which we don't counta lick from presentastio of stim
stimopts.dead_time_lick=0.2; %200ms is the minimum time to process the visual stim, increase this over training
stimopts.time_off_outcome=0.5; %time between licks that give reward (or airpuff)

%Add padding to make sure outcomes all have the same duration
stimopts.max_outcome_duration=max([stimopts.reward_duration, stimopts.air_puff_duration, stimopts.nothing_duration]);
stimopts.reward_duration_padding=stimopts.max_outcome_duration-stimopts.reward_duration;
stimopts.air_puff_duration_padding=stimopts.max_outcome_duration-stimopts.air_puff_duration;
stimopts.nothing_duration_padding=stimopts.max_outcome_duration-stimopts.nothing_duration;

%Delay post outcome
%We want to compensate to make sure all trials have the same duration (because of the fixed number of frames)
stimopts.post_stim_delay=1; %1;
stimopts.post_stim_delay_padding=stimopts.max_stim_delay-stimopts.stim_delay;

%Add a little padding to make sure the CMOS camera is off and ready for the next trial
stimopts.tail_camera_frame_padding=1;

%Build sequences. Reccomend 500 trials of 190 frames (imaging)
stimopts.stim_id = [1 2 3];
stimopts.positive_stim = 3; % might need to counterbalance across mice
stimopts.negative_stim = 1; % might need to counterbalance
stimopts.neutral_stim = 2; % might need to counterbalance
stimopts.stim_prob(stimopts.positive_stim) = 1 ; %positive stim
stimopts.stim_prob(stimopts.neutral_stim) = 0 ; %neutral stim
stimopts.stim_prob(stimopts.negative_stim) = 0 ; %negative stim

%Attribute outcome
stimopts.proba_positive_stim = [1 0 0]; % [reward omission punishment]
stimopts.proba_negative_stim = [0 0 1]; % [reward omission punishment]

stim_type = [];
for i = 1:numel(stimopts.stim_prob)
    stim_type = cat(1,stim_type,repmat(stimopts.stim_id(i),floor(stimopts.stim_prob(i)*N),1));
end

%pad with trial type to match total trial numbers
while size(stim_type,1)<N
    stim_type(end+1) = stimopts.stim_id(randi(length(stimopts.stim_id)));
end

%randomize
stim_type = stim_type(randperm(size(stim_type,1),size(stim_type,1)),:);

%posiitve stim
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

%record in stimopts struct
stimopts.stim_type=stim_type;

if exist('outcome_negative_stim', 'var')
    stimopts.outcome_negative_stim = outcome_negative_stim;
end

if exist('outcome_positive_stim', 'var')
    stimopts.outcome_positive_stim = outcome_positive_stim;
end

%use all the delays to calculate the full length of a block for the behvioral
%camera
total_duration_trial=stimopts.max_stim_delay+stimopts.stim_duration+...
    stimopts.post_stim_delay - 1; % '- 1' end the behCam 1 sec earlier than the end of the post-outcome delay to shorten the file size and smoothen the transition
behav_camera_pulse_dur=ceil(total_duration_trial);

%Behav_cam_off_padding=5; % This might not be necessary or minimized?
Cmd_to_pulse_delay=3;

%save all stim that will be displayed
save_dir = fullfile([app.SaveDirectoryEditField.Value, filesep sprintf('%s_stimInfo.mat', datetime('now', 'Format', 'yyyy-MM-dd-HH-mm'))]);
save(save_dir, 'stimopts', 'opts');
fprintf('Successsfully completed trials info recording\n')
trial_init_time = cell(N, 1);

%% RUN trials
%% Sequence of trials
for i = 1:N
    %Trigger CMOS camera start with a pulse
    digital_out(nidq, nidq_out_list, "trigger", 5/round(app.cur_routine_vals.framerate), 4)
    %Baseline: stim_delay, random between 2 and 4s to prevent mice
    %from knowing when the stim is coming based on LED but spaced by 2
    %frames to make sure we're always at the start of the LED onset
% We removed the white noise as we were worried they were using it as a cue
% to start licking
%     % Play white noise while launching beh camera
%     signal_out = white_noise_only(nidq.Rate, nidq_out_list, total_duration_trial + 2);
%     preload(nidq, signal_out)
%     start(nidq,"RepeatOutput")
% 
    % Launch the python script that turns on the beh camera, and start generating camera pulses
    cmd = sprintf('python %s %d %s %d && exit &', 'C:\Users\mouse1\Documents\GitHub\pySpinCapture\cameraCapture2camsPulse.py', behav_camera_pulse_dur, app.cur_routine_vals.mouse, i);
    system(cmd);
    WaitSecs(Cmd_to_pulse_delay); % Necessary to prevent pulse running before cameara launched
    start(nidq_vid, "Continuous"); % Run pulsing for behCam continuously, and stop it at the end of the trial
    fprintf('Begining Recording %d trial...\n', i);


    %% Start the nidq that will run for the duration of the trial
    %tic;
    trial_init_time{i} = datetime('now', 'Format', 'yyyy-MM-dd-HH-mm-ss');
    %trial starts here
    WaitSecs(stimopts.stim_delay(i));


    %% this is for a fixed grating

    %deliver stimulus (1s fixed)
    %     start_of_showGrating_conditioning(opts,stimopts.stim_type(i));
    %     %New code when interacting with the program that controls the arduino
    %     %Outcome delivery
    %     if stimopts.rewarded_stim(i)
    %         write(dui, "R", "char" );
    %     elseif stimopts.punished_stim(i)
    %         write(dui, "P", "char" );
    %     end
    %     WaitSecs(stimopts.stim_duration);
    %     Screen('Flip', opts.window);

    %% this is for a drifting grating
    %First, start the arduino for the correc situation
    %Outcome delivery
    if stimopts.rewarded_stim(i)
        write(dui, "R", "char" );
        fprintf('Rewarded stim\n');
    elseif stimopts.punished_stim(i)
        write(dui, "P", "char" );
        fprintf('Punished stim\n');
    end
    %then start the movie (you can't do anything while it's playing)
    start_of_showDriftGrating_conditioning(opts,stimopts.stim_type(i), opts.DriftCyclesPerSecond,  stimopts.stim_duration)
    %turn off the arduino when the stim goes off
    write(dui, "O", "char" ); %note it doesn't matter what we send as long as it's neither P nor R

    %wait x sec post stim to make sure we capture whole dynamics of outcome
    %integration
    WaitSecs(stimopts.post_stim_delay+stimopts.post_stim_delay_padding(i));
    %toc

    %Padding to make sure camera is done
    WaitSecs(stimopts.tail_camera_frame_padding);
    stop(nidq_vid);
%     stop(nidq);

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



