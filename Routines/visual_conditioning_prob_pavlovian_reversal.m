function visual_conditioning_prob_pavlovian_reversal(app)
%Visualconditioning Imaging Routine Function
% Adapted from visual_sequence by Camden 2019
% Caroline Jahn & Junchol Park (March 2023)

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
nidq = daq("ni");
nidq.Rate = 3*1e5; % can't be at max, reducing to min 2*max freq of auditory stim

nidq_out_list = ["audio", "airpuff", "water", "trigger"];
addoutput(nidq, "Dev27", "ao0", "Voltage"); % audio
addoutput(nidq, "Dev27", "Port0/Line8", "Digital"); % airpuff
addoutput(nidq, "Dev27", "Port0/Line9", "Digital"); % water
addoutput(nidq, "Dev27", "ao1", "Voltage"); % trigger

nidq_vid = daq("ni");
nidq_vid.Rate = 3*1e5; % 300KHz
ch_pulse = addoutput(nidq_vid, "Dev27", 'ctr0', "PulseGeneration"); % add counter for PulseGeneration
ch_pulse.Frequency = 200; % 500 Hz 300Hz made the cameras crashe, trying 200
ch_pulse.DutyCycle = 0.25;

%Number of trials
N = app.cur_routine_vals.number_trials;

%Initialize Stimuli
stimopts.angle = [0,45,90];
stimopts.contrast = [0.4,0.4,0.4]; %rationale for choice of 40% contrast from https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6623377/
[opts] = InitializeStaticGrating(stimopts.angle,stimopts.contrast);

%Baseline delay (stim delay, jittered)
stimopts.min_stim_delay=2;
stimopts.max_stim_delay=4;
stimopts.stim_delay_step=1/round(app.cur_routine_vals.framerate/2);

stimopts.stim_delay_list = stimopts.min_stim_delay:stimopts.stim_delay_step:stimopts.max_stim_delay;
%draw from uniform ditribution
stimopts.stim_delay_index=randi(length(stimopts.stim_delay_list),N);
%shuffle
stimopts.stim_delay_index=stimopts.stim_delay_index(randperm(length(stimopts.stim_delay_index)));
%store delay for each trial
stimopts.stim_delay=stimopts.stim_delay_list(stimopts.stim_delay_index);

%stim duration (fixed)
stimopts.stim_duration=1;

%Stim outcome delay
stimopts.min_outcome_delay=0.2;
stimopts.max_outcome_delay=0.4;
stimopts.outcome_delay_step=1/round(app.cur_routine_vals.framerate/2);
stimopts.outcome_delay_list=stimopts.min_outcome_delay:stimopts.outcome_delay_step:stimopts.max_outcome_delay;
%draw from uniform ditribution
stimopts.outcome_delay_index=randi(length(stimopts.outcome_delay_list),N);
%shuffle
stimopts.outcome_delay_index=stimopts.outcome_delay_index(randperm(length(stimopts.outcome_delay_index)));
%store delay for each trial
stimopts.outcome_delay=stimopts.outcome_delay_list(stimopts.outcome_delay_index);

%Reward and air puff duration
stimopts.reward_duration=0.05; %recalibrate!
stimopts.air_puff_duration=0.03; 
stimopts.nothing_duration=max(stimopts.reward_duration, stimopts.air_puff_duration);

%Add padding to make sure outcomes all have the same duration
stimopts.max_outcome_duration=max([stimopts.reward_duration, stimopts.air_puff_duration, stimopts.nothing_duration]);
stimopts.reward_duration_padding=stimopts.max_outcome_duration-stimopts.reward_duration;
stimopts.air_puff_duration_padding=stimopts.max_outcome_duration-stimopts.air_puff_duration;
stimopts.nothing_duration_padding=stimopts.max_outcome_duration-stimopts.nothing_duration;

%Delay post outcome
%We want to compensate to make sure all trials have the same duration (because of the fixed number of frames)
stimopts.post_outcome_delay=5;
stimopts.post_outcome_delay_padding=stimopts.max_stim_delay-stimopts.stim_delay + stimopts.max_outcome_delay-stimopts.outcome_delay;

%Add a little padding to make sure the CMOS camera is off and ready for the next trial
stimopts.tail_camera_frame_padding=1;

%Build sequences. Recommend 500 trials of 190 frames (imaging)
stimopts.stim_id = [1 2 3];
stimopts.positive_stim = 1; % was 3 before reversal; % might need to counterbalance across mice
stimopts.negative_stim = 3; % was 1 before reversa1; % might need to counterbalance
stimopts.neutral_stim = 2; % might need to counterbalance
stimopts.stim_prob(stimopts.positive_stim) = 0.455; %positive stim
stimopts.stim_prob(stimopts.neutral_stim) = 0.09; %neutral stim
stimopts.stim_prob(stimopts.negative_stim) = 0.455; %negative stim

%Attribute outcome
stimopts.proba_positive_stim = [0.8 0.1 0.1]; % [reward omission punishment]
stimopts.proba_negative_stim = [0.25 0.1 0.65]; % [reward omission punishment]

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
end

%negative stim
if sum(stim_type==stimopts.negative_stim)>0
    outcome_negative_stim = add_rpo(stimopts.proba_negative_stim, sum(stim_type==stimopts.negative_stim));  
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
    stimopts.max_outcome_delay+stimopts.max_outcome_duration+...
    stimopts.post_outcome_delay - 1; % '- 1' end the behCam 1 sec earlier than the end of the post-outcome delay to shorten the file size and smoothen the transition
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

    % Play white noise while launching beh camera
    signal_out = white_noise_only(nidq.Rate, nidq_out_list, Cmd_to_pulse_delay);
    preload(nidq, signal_out)
    start(nidq,"RepeatOutput")

    % Launch the python script that turns on the beh camera, and start generating camera pulses
    cmd = sprintf('python %s %d %s %d && exit &', 'C:\Users\mouse1\Documents\GitHub\pySpinCapture\cameraCapture2camsPulse.py', behav_camera_pulse_dur, app.cur_routine_vals.mouse, i);
    system(cmd);
    WaitSecs(Cmd_to_pulse_delay); % Necessary to prevent pulse running before cameara launched
    start(nidq_vid, "Continuous"); % Run pulsing for behCam continuously, and stop it at the end of the trial
    fprintf('Begining %d trial...\n', i);

    %Vector of delays for this trial
    delays = get_delay_vec(stimopts, i);
    stop(nidq); % turn off white noise

    %% Start the nidq that will run for the duration of the trial
    signal_out = digital_out_with_white_noise(nidq.Rate, nidq_out_list, delays, stimopts.rewarded_stim(i), stimopts.punished_stim(i));
    preload(nidq, signal_out);
    start(nidq,"RepeatOutput");
    tic;
    trial_init_time{i} = datetime('now', 'Format', 'yyyy-MM-dd-HH-mm-ss');
    %trial starts here
    WaitSecs(stimopts.stim_delay(i));

    %deliver stimulus (1s fixed)
    showGrating_conditioning(opts,stimopts.stim_type(i),stimopts.stim_duration);
    %Outcome delivery
    if stimopts.rewarded_stim(i)
        fprintf('Water')
    elseif stimopts.punished_stim(i)
        fprintf('Air puff')
    else
        fprintf('Nothing')
    end

    %Oucome delay
    WaitSecs(stimopts.outcome_delay(i));

    %Outcome delivery
    if stimopts.rewarded_stim(i)
        WaitSecs(stimopts.reward_duration+stimopts.reward_duration_padding);
    elseif stimopts.punished_stim(i)
        WaitSecs(stimopts.air_puff_duration+stimopts.air_puff_duration_padding);
    else
        WaitSecs(stimopts.nothing_duration+stimopts.nothing_duration_padding);
    end

    %wait 5 sec post outcome to make sure we capture whole dynamics
    WaitSecs(stimopts.post_outcome_delay+stimopts.post_outcome_delay_padding(i));
    %fprintf('\nElapsed time for trial #%d: %.2f sec\n', i, toc); % end timer for the block

    %Padding to make sure camera is done
    WaitSecs(stimopts.tail_camera_frame_padding);
    stop(nidq_vid);
    stop(nidq);
    toc;

    %trial ends here
    fprintf('Done with trial %d\n',i);
end
stimopts.trial_init_time = trial_init_time;
save(save_dir, 'stimopts', '-append') % save trial initiation time
fprintf('Done Recording with session...\n');

pause(10); %this MUST be a pause. WaitSecs does not trigger buffer fill

Screen('closeAll')

end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
