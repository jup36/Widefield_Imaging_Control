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
a.addAnalogInputChannel('Dev27',[0,1,6,7],'Voltage')
a.Rate = app.cur_routine_vals.analog_in_rate;

%Analog Output 
s = daq.createSession('ni');
s.Rate = app.cur_routine_vals.analog_out_rate;
s.addAnalogOutputChannel('Dev27',sprintf('ao%d',app.cur_routine_vals.trigger_out_chan),'Voltage')

%Create and open the log file
log_fn = [app.SaveDirectoryEditField.Value filesep 'acquisitionlog.m'];
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
            (app.behav_cam_vals.duration_in_sec+2*app.behav_cam_vals.flank_duration));
        cmd = sprintf('python "%s" && exit &',filename);
        system(cmd) 
        pause(app.behav_cam_vals.flank_duration); %Start behavioral camera early 
    else    
        WaitSecs(5); %Pre rec pause to allow initialization if no pause from camera initialization
    end


    %% Recording 

    %Trigger camera start with a 10ms pulse
    outputSingleScan(s,4); %deliver the trigger stimuli
    pause(0.01);
    outputSingleScan(s,0); %deliver the trigger stimuli

    %wait until recording reaches desired rec duration
    tic
    while(toc<app.cur_routine_vals.recording_duration)
        continue
    end

    %Post rec pause to make sure everything aquired.
    if app.ofCamsEditField.Value>0  
        pause(app.behav_cam_vals.flank_duration);
    else
        pause(10); 
    end

    a.stop; %Stop aquiring 
    fclose(logfile); %close this log file. 
    delete(lh); %Delete the listener for this log file
    fprintf('Successsfully completed recording. Wrapping up...')
catch %make sure you close the log file and delete the listened if issue
    fclose(logfile);
    delete(lh);
end


