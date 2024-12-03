function resting_state_with_behv_cameras(app)
%record resting state data in chunks of 15min (N defined the number of
%chunks, so N=3 ~ 45min of recording. To be used with the new fast cameras
%at 200Hz. Chunks are because behv cameras would take too long to record
%and might crash if the chunk is too long.

%Add 10s to the CMOS recording to make sure to capture everything that the
%behv cameras are recording, so for a 15min chunks, you want the number of
%frames per trial to be (15 * 60 + 10) x 30 (at 30Hz) = 27,300 frames. Note
%that CMOS will create chunks of the chunks itself to limit buffering! 

%Written by C Jahn April 2024

%%
% device = daq.getDevices;

clearvars -except app;

stimopts.trial_duration = 15; %in min

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
addoutput(nidq, "Dev1", "ao0", "Voltage"); % audio
addoutput(nidq, "Dev1", "Port0/Line0", "Digital"); % airpuff
addoutput(nidq, "Dev1", "Port0/Line1", "Digital"); % water
addoutput(nidq, "Dev1", "ao1", "Voltage"); % trigger

%Create nidq for camera pulses
nidq_vid = daq("ni");
nidq_vid.Rate = 3*1e5; % 300KHz
ch_pulse = addoutput(nidq_vid, "Dev1", 'ctr0', "PulseGeneration"); % add counter for PulseGeneration
ch_pulse.Frequency = 200; % 500 Hz %also hard coded in Camera script, not controlled here
ch_pulse.DutyCycle = 0.25;

%Number of trials
N = app.cur_routine_vals.number_trials;

%use all the delays to calculate the full length of a block for the behvioral
%camera
stimopts.total_duration_trial=stimopts.trial_duration*60;% record in chunks of 15min  

stimopts.behav_camera_pulse_dur=stimopts.total_duration_trial + 2; %ceil(total_duration_sequence)+2; %add 5 s just to be sure to capture everything
stimopts.tail_camera_frame_padding=10; % 10s

%Behav_cam_off_padding=5; % This might not be necessary or minimized?
Cmd_to_pulse_delay=5;

%save all stim that will be displayed
save_dir = fullfile([app.SaveDirectoryEditField.Value, filesep sprintf('%s_stimInfo.mat', datetime('now', 'Format', 'yyyy-MM-dd-HH-mm'))]);
save(save_dir, 'stimopts');
fprintf('Successsfully completed trials info recording\n')
trial_init_time = cell(N, 1);

%% RUN trials
%% Sequence of trials
for i = 1:N %N is the number of chunks
    %Trigger CMOS camera start with a pulse
    digital_out(nidq, nidq_out_list, "trigger", 5/round(app.cur_routine_vals.framerate), 4)
   
    tic

    % Launch the python script that turns on the beh camera, and start generating camera pulses
    cmd = sprintf('python %s %d %s %d && exit &', 'C:\Users\mouse1\Documents\GitHub\pySpinCapture\cameraCapture2camsPulse.py', stimopts.behav_camera_pulse_dur, app.cur_routine_vals.mouse, i);
    system(cmd);
    WaitSecs(Cmd_to_pulse_delay); % Necessary to prevent pulse running before cameara launched
    start(nidq_vid, "Continuous"); % Run pulsing for behCam continuously, and stop it at the end of the trial
    fprintf('Begining Recording %d trial...\n', i);

    trial_init_time{i} = datetime('now', 'Format', 'yyyy-MM-dd-HH-mm-ss');

    WaitSecs(stimopts.total_duration_trial);
    
    toc
    
    %Padding to make sure camera is done
    WaitSecs(stimopts.tail_camera_frame_padding);
    stop(nidq_vid);

    %trial ends here
    fprintf('Done with trial %d\n',i);
    WaitSecs(stimopts.tail_camera_frame_padding);

end
stimopts.trial_init_time = trial_init_time;
save(save_dir, 'stimopts', '-append') % save trial initiation time
fprintf('Done Recording with session...\n');

pause(10); %this MUST be a pause. WaitSecs does not trigger buffer fill

Screen('closeAll')

end

