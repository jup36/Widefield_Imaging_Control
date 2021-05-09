function variable_visual_gratings(app)

%Resting State Imaging Routine Function

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
channels = [0,1,6,7,20,21];
for chan = 1:numel(channels)
    c = channels(chan);
    ch = addAnalogInputChannel(a, 'Dev27', c,'Voltage');
    if c ~= 21
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

%Initialize Stimuli 


%Start listener
lh = addlistener(a,'DataAvailable', @(src,event)LogAquiredData(src,event,logfile));
a.IsContinuous = true;
a.startBackground; %Start aquisition

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

    %Trigger camera start with a 10ms pulse
    outputSingleScan(s,4); %deliver the trigger stimuli
    WaitSecs(0.01);
    outputSingleScan(s,0); %deliver the trigger stimuli
        
    %wait until recording reaches desired rec duration
    tic    
    
%     stim_type = ones(4,floor(app.cur_routine_vals.number_trials/4)) .* (1:4)';
    stim_type = ones(3,floor(app.cur_routine_vals.number_trials/3)) .* (1:3)';
    stim_type = stim_type(:);
    stim_type = stim_type(randperm(numel(stim_type)));
    
    
    %loop through your stimuli. This is a lazy man's way of doing it (i.e.
    %have to manually make sure you don't have more stimuli than the
    %duration of the recording. but this isn't hard to set. 
    for i = 1:numel(stim_type)
        fprintf('\n delivering stim %d',i);
        WaitSecs(randi([6 8],1)); 
        if stim_type(i) == 2 %visual
            outputSingleScan(q,4);
            WaitSecs(0.25);
            outputSingleScan(q,0);
        elseif stim_type(i) == 3 %audio
            queueOutputData(r,tone1);
            r.startForeground;
        elseif stim_type(i) == 4 %whisker stim through air pulse
            p.outputSingleScan([1]);
            WaitSecs(0.2);
            p.outputSingleScan([0]);
        end
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
    save([app.SaveDirectoryEditField.Value,filesep 'stimInfo.m'],'stim_type'); 
    save([app.SaveDirectoryEditField.Value,filesep 'recordingparameters.m'],'recordingparameters');   
    fprintf('Successsfully completed recording. Wrapping up...')
        
catch %make sure you close the log file and delete the listened if issue
    fclose(logfile);
    delete(lh);
end


