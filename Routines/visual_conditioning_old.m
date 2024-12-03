function visual_conditioning_old(app)

%Retinotopy Imaging Routine Function

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
nidq.Rate = 9*1e5; % 900K Hz;

%
nidq_out_list = ["audio", "airpuff", "water","trigger"]; 
addoutput(nidq, "Dev27", "ao0", "Voltage"); % audio
addoutput(nidq, "Dev27", "Port0/Line8", "Digital"); % airpuff
addoutput(nidq, "Dev27", "Port0/Line9", "Digital"); % water
addoutput(nidq, "Dev27", "ao1", "Voltage"); % trigger

%we record everything through spike glx, if not the case, we need to add
%analog in to record as Camden did. Pb: addind analog inputs reduce the
%rate and we need a high rate for the auditory stim

% a.addAnalogInputChannel('Dev27',[0,1,6,7,20,21],'Voltage')
% a.Rate = app.cur_routine_vals.analog_in_rate;
% channels = [app.cur_routine_vals.expose_out_chan,...
%             app.cur_routine_vals.stimopts,...
%             app.cur_routine_vals.trigger_ready_chan];

% channels = [app.cur_routine_vals.expose_out_chan,...
%             app.cur_routine_vals.stimopts,...
%             app.cur_routine_vals.photodiode_chan,...
%             app.cur_routine_vals.trigger_ready_chan,...
%             app.cur_routine_vals.lick_readout_chan];

% for chan = 1:numel(channels)
%     c = sprintf('ai%d',chan-1);
%     ch = addinput(nidq, "Dev27", c, "Voltage"); %addAnalogInputChannel(a, 'Dev27', c,'Voltage');
%     if c ~= app.cur_routine_vals.photodiode_chan && c ~= app.cur_routine_vals.lick_readout_chan
%         ch.TerminalConfig = 'SingleEnded';
%     end
% end
% a.Rate = app.cur_routine_vals.analog_in_rate;

% %Analog Output
% s = daq.createSession('ni');
% s.Rate = app.cur_routine_vals.analog_out_rate;
% s.addAnalogOutputChannel('Dev27',sprintf('ao%d',app.cur_routine_vals.trigger_out_chan),'Voltage')
% 
% %Digital Output
% s_rew = daq.createSession('ni');
% s_rew.Rate = app.cur_routine_vals.analog_out_rate;
% s_rew.addDigitalChannel('Dev27',sprintf('ao%d',app.cur_routine_vals.reward_out_chan),'Voltage')

% %Create and open the log file
% log_fn = [app.SaveDirectoryEditField.Value filesep sprintf('%s_acquisitionlog.m',datestr(now,'mm-dd-yyyy-HH-MM'))];
% logfile = fopen(log_fn,'w');

%Initialize Stimuli
stimopts.stim_names = {'A','B','C'};
stimopts.angle = [0,45,90];
stimopts.contrast = [1,1,1]; %rationale for choice of 40% contrast from https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6623377/
[opts] = InitializeStaticGrating(stimopts.angle,stimopts.contrast);
stimopts.reward_duration=0.25;
stimopts.air_puff_duration=0.1;

%Build sequences. Reccomend 500 trials of 190 frames (imaging)
stimopts.stim_prob = [1/3 1/3 1/3];
stimopts.stim_id = [ 1 2 3 ];
stimopts.rewarded_stim = 3; % might need to counterbalance
stimopts.punished_stim = 1; % might need to counterbalance

N = app.cur_routine_vals.number_trials;
stimopts.reward_delay = unifrnd(1, 2, N, 1);
stimopts.punishment_delay = unifrnd(1, 2, N, 1);

stim_type = [];
for i = 1:numel(stimopts.stim_prob)
    stim_type = cat(1,stim_type,repmat(stimopts.stim_id(i),floor(stimopts.stim_prob(i)*N),1));
end
%randomize
stim_type = stim_type(randperm(size(stim_type,1),size(stim_type,1)),:);

%pad with trial type to match total trial numbers
if size(stim_type,1)<N
    warning('padding to match number of trials');
    stim_type = cat(1,stim_type, repmat(stimopts.seq_id(1,:),N-size(stim_type,1),1));
end
rewarded_stim = (stim_type == stimopts.rewarded_stim);
punished_stim = (stim_type == stimopts.punished_stim);

%record in stimopts struct
stimopts.stim_type=stim_type;
stimopts.rewarded_stim=rewarded_stim;
stimopts.punished_stim=punished_stim;

%No more lisetner as we record on spike glx but need to be added if not
% %Start listener
% lh = addlistener(a,'DataAvailable', @(src,event)LogAquiredData(src,event,logfile));
% a.IsContinuous = true;
% a.startBackground; %Start aquisition

%get random ITI. For less jitter relative to exposure - choose interval.
%divide by two so that it's an interval of a single wavelength
ITI = [1*round(app.cur_routine_vals.framerate/2), 2*round(app.cur_routine_vals.framerate/2)];
stimopts.ITI=ITI;

%save all stim that will be displayed
recordingparameters = {app.cur_routine_vals,app.behav_cam_vals};
save([app.SaveDirectoryEditField.Value,filesep sprintf('%s_stimInfo.mat',datestr(now,'mm-dd-yyyy-HH-MM'))],'stimopts');
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
    
    %% Recording
    
    %loop through trials
    for i = 1:size(stim_type,1)
        %Trigger camera start with a 10ms pulse
        %outputSingleScan(s,4); %deliver the trigger stimuli
        %WaitSecs(5/round(app.cur_routine_vals.framerate)); %base on exposure length
        %outputSingleScan(s,0); %deliver the trigger stimuli
        digital_out(nidq, nidq_out_list, "trigger", 5/round(app.cur_routine_vals.framerate))
        
        %wait a random interval based on exposure length
        WaitSecs(randi(ITI,1)*1/round(app.cur_routine_vals.framerate/2));
        
        %deliver stimulus
        showGrating_conditioning(opts,stim_type(i),2)
        WaitSecs(stimopts.reward_delay(i))
        
        %reward delivery
        if rewarded_stim(i)
            digital_out(nidq, nidq_out_list, "water", stimopts.reward_duration)
%             outputSingleScan(s_rew,5); %deliver the trigger stimuli
%             WaitSecs(stimopts.reward_size); %base on exposure length
%             outputSingleScan(s_rew,0); %deliver the trigger stimuli
        elseif punished_stim(i)
            digital_out(nidq, nidq_out_list, "airpuff", stimopts.air_puff_duration)
        else
            WaitSecs(0.2)
        end
        
        %wait 2 sec post stim.
        WaitSecs(3.5)      
        
        fprintf('\n\tDone with trial %d',i);
        
    end
    
    fprintf('\nDone Recording... Filling buffer and wrapping up...');
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


