function visual_conditioning(app)

%Visualconditioning Imaging Routine Function
%Adapted from visual_sequence by Camden
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

nidq_out_list = ["audio", "airpuff", "water","trigger"]; 
addoutput(nidq, "Dev27", "ao0", "Voltage"); % audio
addoutput(nidq, "Dev27", "Port0/Line8", "Digital"); % airpuff
addoutput(nidq, "Dev27", "Port0/Line9", "Digital"); % water
addoutput(nidq, "Dev27", "ao1", "Voltage"); % trigger


%we record everything through spike glx, if not the case, we need to add
%analog in to record as Camden did. Pb: addind analog inputs reduce the
%rate and we need a high rate for the auditory stim

%Number of trials
N = app.cur_routine_vals.number_trials;

%Initialize Stimuli
stimopts.angle = [0,45,90];
stimopts.contrast = [1,1,1]; %rationale for choice of 40% contrast from https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6623377/
[opts] = InitializeStaticGrating(stimopts.angle,stimopts.contrast);

%Baseline delay
stimopts.min_stim_delay=2;
stimopts.max_stim_delay=6;
stimopts.stim_delay_step=1/round(app.cur_routine_vals.framerate/2);

stimopts.stim_delay_list = stimopts.min_stim_delay:stimopts.stim_delay_step:stimopts.max_stim_delay;

%stim duration
stimopts.stim_duration=1;

%draw from uniform ditribution
stimopts.stim_delay_index=randi(length(stimopts.stim_delay_list),N);
%shuffle
stimopts.stim_delay_index=stimopts.stim_delay_index(randperm(length(stimopts.stim_delay_index)));
%store delay for each trial
stimopts.stim_delay=stimopts.stim_delay_list(stimopts.stim_delay_index);

%Reward and air puff duration
stimopts.reward_duration=0.25;
stimopts.air_puff_duration=0.1;
stimopts.nothing_duration=0.2;

%Add padding to make sure outcomes all have the same duration
stimopts.max_outcome_delay=max([stimopts.reward_duration, stimopts.air_puff_duration, stimopts.nothing_duration]);

stimopts.reward_duration_padding=stimopts.max_outcome_delay-stimopts.reward_duration;
stimopts.air_puff_duration_padding=stimopts.max_outcome_delay-stimopts.air_puff_duration;
stimopts.nothing_duration_padding=stimopts.max_outcome_delay-stimopts.nothing_duration;

%Delay between stim and outcome
stimopts.outcome_delay = 0.5;

%Dealy post outcome
%We want to compensate to make sure all trials have the same duration
%(because of the fixed number of frames)
stimopts.post_outcome_delay  = 7;
stimopts.post_outcome_delay_padding=stimopts.max_stim_delay-stimopts.stim_delay;

%Add a little padding to ake sure the camera is off
stimopts.tail_camera_frame_padding=1;

%Build sequences. Reccomend 500 trials of 190 frames (imaging)
stimopts.stim_prob = [1/3 1/3 1/3];
stimopts.stim_id = [ 1 2 3 ];
stimopts.rewarded_stim = 3; % might need to counterbalance
stimopts.punished_stim = 1; % might need to counterbalance

stim_type = [];
for i = 1:numel(stimopts.stim_prob)
    stim_type = cat(1,stim_type,repmat(stimopts.stim_id(i),floor(stimopts.stim_prob(i)*N),1));
end
%randomize
stim_type = stim_type(randperm(size(stim_type,1),size(stim_type,1)),:);

%pad with trial type to match total trial numbers
%pad with trial type to match total trial numbers
while size(stim_type,1)<N
    warning('padding to match number of trials');
    stim_type(end+1) = stimopts.stim_id(randi(length(stimopts.stim_id)));
end
%record in stimopts struct
stimopts.stim_type=stim_type;
stimopts.rewarded_stim = (stim_type == stimopts.rewarded_stim);
stimopts.punished_stim = (stim_type == stimopts.punished_stim);


%No more lisetner as we record on spike glx but need to be added if not
%get random ITI. For less jitter relative to exposure - choose interval.
%divide by two so that it's an interval of a single wavelength

%save all stim that will be displayed
recordingparameters = {app.cur_routine_vals,app.behav_cam_vals};
save([app.SaveDirectoryEditField.Value,filesep sprintf('%s_stimInfo.mat',datestr(now,'mm-dd-yyyy-HH-MM'))],'stimopts','opts');
save([app.SaveDirectoryEditField.Value,filesep sprintf('%s_recordingparameters.mat',datestr(now,'mm-dd-yyyy-HH-MM'))],'recordingparameters');
fprintf('Successsfully completed recording')

try %recording loop catch to close log file and delete listener
    %% Start behavioral aquisition

    %update with new cameras
    if app.ofCamsEditField.Value>0
        filename = CreateVideoRecordingScript([app.rootdir filesep 'Behavioral_MultiCam' filesep],...
            [app.SaveDirectoryEditField.Value filesep],app.behav_cam_vals,'duration_in_sec',...
            (app.behav_cam_vals.duration_in_sec+app.behav_cam_vals.flank_duration+10));
        cmd = sprintf('python "%s" && exit &',filename);
        system(cmd)
        WaitSecs(10); %Start behavioral camera early since takes a few secs to build up
    else
        WaitSecs(5); %Pre rec pause to allow initialization if no pause from camera initialization
    end
    fprintf('\nBegining Recording');
    
    %% Sequence of trials
    for i = 1:size(stimopts.stim_type,1)
        %Trigger camera start with a 10ms pulse
        digital_out(nidq, nidq_out_list, "trigger", 5/round(app.cur_routine_vals.framerate), 4)
        %Baseline: stim_delay, random between 2 and 6s to prevent mice
        %from knowing when the stim is coming based on LED but spaced by 2
        %frames to make sure we're always at the start of the LED onset
        WaitSecs(stimopts.stim_delay(i))

        %deliver stimulus (1s fixed)
        showGrating_conditioning(opts,stimopts.stim_type(i),stimopts.stim_duration)

        %Oucome delay: 0.5s fixed for trace conditioning. Might add jitter
        %later
        WaitSecs(stimopts.outcome_delay)

        %Outcome delivery
        if stimopts.rewarded_stim(i)
            digital_out(nidq, nidq_out_list, "water", stimopts.reward_duration, 1)
            WaitSecs(stimopts.reward_duration_padding)
        elseif stimopts.punished_stim(i)
            digital_out(nidq, nidq_out_list, "airpuff", stimopts.air_puff_duration, 1)
            WaitSecs(stimopts.air_puff_duration_padding)
        else
            WaitSecs(stimopts.nothing_duration)
            WaitSecs(stimopts.nothing_duration_padding)
        end
        
        %wait 7 sec post outcome to mke sure we get the whole dynamics
        WaitSecs(stimopts.post_outcome_delay)      
        WaitSecs(stimopts.post_outcome_delay_padding(i));
        fprintf('\n\tDone with trial %d',i);
        
        %Padding to make sure camera is done
        WaitSecs(stimopts.tail_camera_frame_padding)
    end
    
    fprintf('\nDone Recording...');
    %Post rec pause to make sure everything aquired.
    if app.ofCamsEditField.Value>0
        WaitSecs(app.behav_cam_vals.flank_duration);
    else
        WaitSecs(10);
    end
    
    pause(10); %this MUST be pause. WaitSecs does not trigger buffer fill
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

