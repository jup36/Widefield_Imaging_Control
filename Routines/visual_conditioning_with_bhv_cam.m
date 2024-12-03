function visual_conditioning_with_bhv_cam(app)

%Visualconditioning Imaging Routine Function
%Adapted from visual_sequence by Camden 2019
%Caroline Jahn & Junchol Park (March 2023)

%Can't synch screens, but no proeblem because we're using the photodiode
%anyway
Screen('Preference','SkipSyncTests', 1);

%check if save directory exists
if ~exist(app.SaveDirectoryEditField.Value)
    mkdir(app.SaveDirectoryEditField.Value)
else
    %confirm no log file already in ithe directory... to be extra safe,
    %adding timestamp to all filenames
    if exist([app.SaveDirectoryEditField.Value '%s_acquisitionlog.m'])~=0
        uialert(app.UIFigure,['Save dir already contains log file. Aquisition cancelled.\n',...
            'Select new save directory and try again'],'Overwrite Notice')
        return
    end
end

%% Initialize inputs/outputs and log file
%Analog Inputs
nidq = daq("ni");
nidq.Rate = 3*1e5; % can't be at max, reducing to min 2*max freq of auditory stim

nidq_out_list = ["audio","airpuff", "water","trigger"];
addoutput(nidq, "Dev27", "ao0", "Voltage"); % audio
addoutput(nidq, "Dev27", "Port0/Line8", "Digital"); % airpuff
addoutput(nidq, "Dev27", "Port0/Line9", "Digital"); % water
addoutput(nidq, "Dev27", "ao1", "Voltage"); % trigger

nidq_vid = daq("ni");
nidq_vid.Rate = 3*1e5; % 300KHz
ch_pulse = addoutput(nidq_vid, "Dev27", 'ctr0', "PulseGeneration");
ch_pulse.Frequency = 500; % 500 Hz
ch_pulse.DutyCycle = 0.25;

% nidq_audio = daq("ni"); 
% nidq_audio.Rate = 3*1e5; % 300KHz
% ch_audio = addoutput(nidq_audio, "Dev27", "ao0", "Voltage"); % audio for white noise;

%we record everything through spike glx, if not the case, we need to add
%analog in to record as Camden did. Pb: addind analog inputs reduce the
%rate and we need a high rate for the auditory stim

%Number of trials
N = app.cur_routine_vals.number_trials;

%Initialize Stimuli
stimopts.angle = [0,45,90];
stimopts.contrast = [0.4,0.4,0.4]; %rationale for choice of 40% contrast from https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6623377/
[opts] = InitializeStaticGrating(stimopts.angle,stimopts.contrast);

%Baseline delay
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

%stim duration
stimopts.stim_duration=1;

%Delay between stim and outcome
stimopts.outcome_delay = 0.5;

%Reward and air puff duration
stimopts.reward_duration=0.25;
stimopts.air_puff_duration=0.1;
stimopts.nothing_duration=0.2;

%Add padding to make sure outcomes all have the same duration
stimopts.max_outcome_duration=max([stimopts.reward_duration, stimopts.air_puff_duration, stimopts.nothing_duration]);

stimopts.reward_duration_padding=stimopts.max_outcome_duration-stimopts.reward_duration;
stimopts.air_puff_duration_padding=stimopts.max_outcome_duration-stimopts.air_puff_duration;
stimopts.nothing_duration_padding=stimopts.max_outcome_duration-stimopts.nothing_duration;

%Dealy post outcome
%We want to compensate to make sure all trials have the same duration
%(because of the fixed number of frames)
stimopts.post_outcome_delay = 5;
stimopts.post_outcome_delay_padding=stimopts.max_stim_delay-stimopts.stim_delay;

%Add a little padding to ake sure the CMOS camera is off
stimopts.tail_camera_frame_padding=1;

%Build sequences. Reccomend 500 trials of 190 frames (imaging)
stimopts.stim_prob = [1/3 1/3 1/3];
stimopts.stim_id = [ 1 2 3 ];
stimopts.rewarded_stim = 3; % might need to counterbalance
stimopts.punished_stim = 1; % might need to counterbalance
stimopts.block_size = 12;
stimopts.N_blocks=floor(N/stimopts.block_size);

stim_type = [];
for i = 1:numel(stimopts.stim_prob)
    stim_type = cat(1,stim_type,repmat(stimopts.stim_id(i),floor(stimopts.stim_prob(i)*N),1));
end
%randomize
stim_type = stim_type(randperm(size(stim_type,1),size(stim_type,1)),:);

%Block number
block_nb=meshgrid(1:stimopts.N_blocks,1:stimopts.block_size);
block_nb=reshape(block_nb,size(block_nb,1)*size(block_nb,2),1);

%bTrial index in block
block_idx=meshgrid(1:stimopts.block_size,1:stimopts.N_blocks);
block_idx=reshape(block_idx',size(block_idx,1)*size(block_idx,2),1);

%pad with trial type to match total trial numbers
%pad with trial type to match total trial numbers
while size(stim_type,1)<N
    %warning('padding stim_type to match number of trials');
    stim_type(end+1) = stimopts.stim_id(randi(length(stimopts.stim_id)));
end

if size(stim_type,1)>size(block_nb,1) %if we had to pad then had a block
    %warning('padding block_nb to match number of trials');
    stimopts.N_blocks=stimopts.N_blocks+1;
    block_nb(end+1:size(stim_type,1))=stimopts.N_blocks;
    block_idx(end+1:size(stim_type,1))=1:size(stim_type,1)-size(block_idx,1);
end

%record in stimopts struct
stimopts.stim_type=stim_type;
stimopts.rewarded_stim = (stim_type == stimopts.rewarded_stim);
stimopts.punished_stim = (stim_type == stimopts.punished_stim);
stimopts.block_nb = block_nb;
stimopts.block_idx = block_idx;

%use al the dealys to calculat the full length of a block for the behvioral
%camera
total_duration_trial=stimopts.max_stim_delay+stimopts.stim_duration+stimopts.outcome_delay+stimopts.max_outcome_duration+stimopts.post_outcome_delay+stimopts.tail_camera_frame_padding;
behav_camera_pulse_dur=round(stimopts.block_size*total_duration_trial + 10); %added 10s because we accumulate delay over the block, empiracally tested with this config. Must be tested if changing the delays/number of trials in block.

Behav_cam_off_padding=5;
Cmd_to_pulse_delay=5;

%No more lisetner as we record on spike glx but need to be added if not
%get random ITI. For less jitter relative to exposure - choose interval.
%divide by two so that it's an interval of a single wavelength

%save all stim that will be displayed
%recordingparameters = {app.cur_routine_vals,app.behav_cam_vals};
save([app.SaveDirectoryEditField.Value,filesep sprintf('%s_stimInfo.mat',datestr(now,'mm-dd-yyyy-HH-MM'))],'stimopts','opts');
%save([app.SaveDirectoryEditField.Value,filesep sprintf('%s_recordingparameters.mat',datestr(now,'mm-dd-yyyy-HH-MM'))],'recordingparameters');
fprintf('Successsfully completed trial info recording\n')

%initiate the camera block to 0
current_camera_block=0;

try %recording loop catch to close log file and delete listener

    %% Sequence of trials
    for i = 1:size(stimopts.stim_type,1)
        %we are now recording the behavioral camera in blocks of trials
        %first we check if we have changed block and we turn on the camera
        if current_camera_block==stimopts.block_nb(i)-1
            if current_camera_block>0
                toc
                stop(nidq)
            end
            %add white noise in the background
            signal_out = white_noise_only(nidq.Rate, nidq_out_list, Behav_cam_off_padding+Cmd_to_pulse_delay);
            preload(nidq, signal_out)
            start(nidq,"RepeatOutput")
            if current_camera_block>0
                WaitSecs(Behav_cam_off_padding) %pause(Behav_cam_off_padding) %make sure that the previous axcquisition is over
            end
            %launch the python script that turns on the camera + matlab
            cmd = sprintf('python %s %d %s %d && exit &', 'C:\Users\mouse1\Documents\GitHub\pySpinCapture\cameraCapturePulse.py',behav_camera_pulse_dur, app.cur_routine_vals.mouse, stimopts.block_nb(i));
            system(cmd);
            WaitSecs(Cmd_to_pulse_delay);
            start(nidq_vid, "Continuous"); %start(nidq_vid, "NumScans", behav_camera_pulse_dur*nidq_vid.Rate);
            fprintf('\nBegining Recording %d block recording...\n',stimopts.block_nb(i));
            current_camera_block=current_camera_block+1;
            tic
            stop(nidq)
        end
        if i>1
            stop(nidq)
        end
        %Trigger CMOS camera start with a 10ms pulse
        %digital_out(nidq, nidq_out_list, "trigger", 5/round(app.cur_routine_vals.framerate), 4)
        %Baseline: stim_delay, random between 2 and 6s to prevent mice
        %from knowing when the stim is coming based on LED but spaced by 2
        %frames to make sure we're always at the start of the LED onset

        %Vector of delays for this trial
        if stimopts.rewarded_stim(i)
            delays=[stimopts.stim_delay(i), stimopts.stim_duration, ... 
                    stimopts.outcome_delay, stimopts.reward_duration, ...
                    stimopts.reward_duration_padding, stimopts.post_outcome_delay, ... 
                    stimopts.post_outcome_delay_padding(i), stimopts.tail_camera_frame_padding];
        elseif stimopts.punished_stim(i)
            delays=[stimopts.stim_delay(i), stimopts.stim_duration, ... 
                    stimopts.outcome_delay, stimopts.air_puff_duration, ...
                    stimopts.air_puff_duration_padding, stimopts.post_outcome_delay,...
                    stimopts.post_outcome_delay_padding(i), stimopts.tail_camera_frame_padding];
        else
            delays=[stimopts.stim_delay(i), stimopts.stim_duration, stimopts.outcome_delay,...
                stimopts.nothing_duration, stimopts.nothing_duration_padding, stimopts.post_outcome_delay,...
                stimopts.post_outcome_delay_padding(i), stimopts.tail_camera_frame_padding];
        end
       
        %start the nidq that will run for the duration of the trial
        signal_out = digital_out_with_white_noise(nidq.Rate, nidq_out_list, delays,  stimopts.rewarded_stim(i), stimopts.punished_stim(i));
        preload(nidq, signal_out)
        start(nidq,"RepeatOutput")

        %trial starts here
        pause(stimopts.stim_delay(i));

        %deliver stimulus (1s fixed)
        showGrating_conditioning(opts,stimopts.stim_type(i),stimopts.stim_duration);

        %Oucome delay: 0.5s fixed for trace conditioning. Might add jitter
        %later
        pause(stimopts.outcome_delay);

        %Outcome delivery
        if stimopts.rewarded_stim(i)
            pause(stimopts.reward_duration+stimopts.reward_duration_padding);
        elseif stimopts.punished_stim(i)
            pause(stimopts.air_puff_duration+stimopts.air_puff_duration_padding)
        else
            pause(stimopts.nothing_duration+stimopts.nothing_duration_padding)
        end

        %wait 5 sec post outcome to mke sure we capture whole dynamics
        pause(stimopts.post_outcome_delay+stimopts.post_outcome_delay_padding(i))

        %Padding to make sure camera is done
        pause(stimopts.tail_camera_frame_padding)
       
        %trial ends here
        fprintf('\n\tDone with trial %d\n',i);
       
    end

    fprintf('\nDone Recording...\n');
    %Post rec pause to make sure everything aquired.
    if app.ofCamsEditField.Value>0
        WaitSecs(app.behav_cam_vals.flank_duration);
    else
        WaitSecs(10);
    end

    pause(10); %this MUST be a pause. WaitSecs does not trigger buffer fill
    %     a.stop; %Stop aquiring
    %     fprintf('\nSaving Log ... Please wait')
    %     fclose(logfile); %close this log file.
    %     delete(lh); %Delete the listener for this log file
    %     fprintf('\nSuccesssfully completed recording.')
    %     recordingparameters = {app.cur_routine_vals,app.behav_cam_vals};
    %     save([app.SaveDirectoryEditField.Value,filesep sprintf('%s_stimInfo.mat',datestr(now,'mm-dd-yyyy-HH-MM'))],'stimopts');
    %     save([app.SaveDirectoryEditField.Value,filesep sprintf('%s_recordingparameters.mat',datestr(now,'mm-dd-yyyy-HH-MM'))],'recordingparameters');
    %     fprintf('Successsfully completed recording. Wrapping up...')
    Screen('closeAll')

catch %make sure you close the log file and delete the listened if issue
    %     fclose(logfile);
    %     delete(lh);
end


