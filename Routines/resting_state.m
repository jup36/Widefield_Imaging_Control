function resting_state(app)

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
% channels = [0,1,6,7,20,21];
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
log_fn = [app.SaveDirectoryEditField.Value filesep sprintf('%s_acquisitionlog.m',datestr(now,'mm-dd-yyyy-HH-MM'))];
logfile = fopen(log_fn,'w');

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
    save([app.SaveDirectoryEditField.Value filesep sprintf('%s_recordingparameters.mat',datestr(now,'mm-dd-yyyy-HH-MM'))],'recordingparameters');
    
catch %make sure you close the log file and delete the listened if issue
    fclose(logfile);
    delete(lh);
end
end %function


