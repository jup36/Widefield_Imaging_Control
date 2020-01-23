function resting_state_withAV(app)

%Resting State Imaging Routine Function with audio and visual stim

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
channels = [0,1,2,6,7,16,20,21];
for chan = 1:numel(channels)
    c = channels(chan);
    ch = addAnalogInputChannel(a, 'Dev27', c,'Voltage');
    if c ~= 21
        ch.TerminalConfig = 'SingleEnded';
    end
end
a.Rate = app.cur_routine_vals.analog_in_rate;

%Analog Output for microscope
s = daq.createSession('ni');
s.Rate = app.cur_routine_vals.analog_out_rate;
s.addAnalogOutputChannel('Dev27',sprintf('ao%d',app.cur_routine_vals.trigger_out_chan),'Voltage');

%Analog Output for LEDs
q = daq.createSession('ni');
q.addAnalogOutputChannel('Dev27',sprintf('ao%d',app.cur_routine_vals.trigger_LED_chan), 'Voltage');

%Analog Output for Speaker and preload sinusoid
r = daq.createSession('ni');
r.Rate = app.cur_routine_vals.analog_out_rate;
r.addAnalogOutputChannel('Dev27',sprintf('ao%d',app.cur_routine_vals.trigger_speaker_chan), 'Voltage');
amp = 1;
tone1 = sin(linspace(90000, pi*2,r.Rate)') * amp;
tone1 = tone1(1:r.Rate*0.25);

%Digital Output for air solenoid
p = daq.createSession('ni');
p.addDigitalChannel('Dev27', 'Port0/Line0:10', 'OutputOnly');

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
    WaitSecs(0.01);
    outputSingleScan(s,0); %deliver the trigger stimuli

    %wait until recording reaches desired rec duration
    tic    
    stim_type = ones(4,floor(app.cur_routine_vals.number_trials/4)) .* (1:4)';
    stim_type = stim_type(:);
    stim_type = stim_type(randperm(numel(stim_type)));
    
    
    %main loop
    for i = 1:numel(stim_type)
        fprintf('\n delivering stim %d',i);
        WaitSecs(randi([5 7],1)); 
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
%         if toc<app.cur_routine_vals.recording_duration
%             break
%         end
    end
    
    while toc<app.cur_routine_vals.recording_duration
        continue
    end

    %Post rec pause to make sure everything aquired.
    if app.ofCamsEditField.Value>0  
        WaitSecs(app.behav_cam_vals.flank_duration);
    else
        WaitSecs(10); 
    end

    a.stop; %Stop aquiring 
    fclose(logfile); %close this log file. 
    delete(lh); %Delete the listener for this log file
    save([app.SaveDirectoryEditField.Value,filesep 'stimInfo.m'],'stim_type'); 
    save([app.SaveDirectoryEditField.Value,filesep 'recordingparameters.m'],'app');   
    fprintf('Successsfully completed recording. Wrapping up...')
    
    
catch %make sure you close the log file and delete the listened if issue
    fclose(logfile);
    delete(lh);
end


