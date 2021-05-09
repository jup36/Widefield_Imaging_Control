function retinotopy(app)

%Retinotopy Imaging Routine Function

%check if save directory exists
if ~exist(app.SaveDirectoryEditField.Value)
    mkdir(app.SaveDirectoryEditField.Value)
else
    %confirm no log file already in ithe directory
    if exist([app.SaveDirectoryEditField.Value 'acquisitionlog.m'])~=0
        uialert(app.UIFigure,['Save dir already contains log file. Aquisition cancelled.\n',...
            'Select new save directory and try again'],'Overwrite Notice')     
        return
    end
end

%% Initialize inputs/outputs and log file
%Analog Inputs
a = daq.createSession('ni');
% a.addAnalogInputChannel('Dev27',[0,1,6,7,20,21],'Voltage')
% a.Rate = app.cur_routine_vals.analog_in_rate;
channels = [app.cur_routine_vals.expose_out_chan,...
    app.cur_routine_vals.frame_readout_chan,...
    app.cur_routine_vals.photodiode_chan,...
    app.cur_routine_vals.trigger_ready_chan];
    
for chan = 1:numel(channels)
    c = channels(chan);
    ch = addAnalogInputChannel(a, 'Dev27', c,'Voltage');
    if c ~= app.cur_routine_vals.photodiode_chan
        ch.TerminalConfig = 'SingleEnded';
    end
end
a.Rate = app.cur_routine_vals.analog_in_rate;

%Analog Output 
s = daq.createSession('ni');
s.Rate = app.cur_routine_vals.analog_out_rate;
s.addAnalogOutputChannel('Dev27',sprintf('ao%d',app.cur_routine_vals.trigger_out_chan),'Voltage')

%Create and open the log file
log_fn = [app.SaveDirectoryEditField.Value filesep 'acquisitionlog.m'];
logfile = fopen(log_fn,'w');

%Initialize and Randomize Stimuli 
[retinoOpts] = InitializeRetinotopy(5, 150); %5 seconds = 9degree/sec for 45 degree screen
stim_type = ones(4,floor(app.cur_routine_vals.number_trials/4)) .* (1:4)'; %40 trials with 6second iti = <30min
stim_type = stim_type(:);
stim_type = stim_type(randperm(numel(stim_type)));

%Start listener
lh = addlistener(a,'DataAvailable', @(src,event)LogAquiredData(src,event,logfile));
a.IsContinuous = true;
a.startBackground; %Start aquisition

%get random ITI. For less jitter relative to exposure - choose interval
ITI = [4.5*round(app.cur_routine_vals.framerate),6*round(app.cur_routine_vals.framerate)];
try %recording loop catch to close log file and delete listener
    %% Start behavioral aquisition
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

    tic %wait until recording reaches desired rec duration
    
    %Trigger camera start with a 10ms pulse 
    outputSingleScan(s,4); %deliver the trigger stimuli    
    WaitSecs(0.1); 
    outputSingleScan(s,0); %deliver the trigger stimuli
    
    %short burn-in period to let LED level out
    WaitSecs(15);       
  
    %loop through your stimuli. This is a lazy man's way of doing it (i.e. have to manually make sure you don't have more stimuli than the duration of the recording. but this isn't hard to precompute
    for i = 1:numel(stim_type)          
        WaitSecs(randi(ITI,1)*1/round(app.cur_routine_vals.framerate));%to llimit jitter between imaging frames and stimulus presentation,choose intervales that are a multiple of exposure duration
        fprintf('\n delivering stim %d',i);       
        showRetinotopy(retinoOpts,stim_type(i));         
    end
    
    while(toc<app.cur_routine_vals.recording_duration)
        continue
    end
    
    fprintf('\nDone Recording... Filling buffer and wrapping up...');
    %Post rec pause to make sure everything aquired.
    if app.ofCamsEditField.Value>0  
        WaitSecs(app.behav_cam_vals.flank_duration);
    else
        WaitSecs(10); 
    end
    
    pause(10); %this MUST be pause. WaitSecs does not trigger buffer fill 
    a.stop; %Stop aquiring 
    fprintf('\nSaving Log ... Please wait')
    fclose(logfile); %close this log file.     
    delete(lh); %Delete the listener for this log file
    fprintf('\nSuccesssfully completed recording.')
    recordingparameters = {app.cur_routine_vals,app.behav_cam_vals}; 
    save([app.SaveDirectoryEditField.Value,filesep 'stimInfo.mat'],'stim_type'); 
    save([app.SaveDirectoryEditField.Value,filesep 'recordingparameters.mat'],'recordingparameters');   
    fprintf('Successsfully completed recording. Wrapping up...')
    Screen('closeAll')
        
catch %make sure you close the log file and delete the listened if issue
    fclose(logfile);
    delete(lh);
end


