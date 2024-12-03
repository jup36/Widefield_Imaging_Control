function visual_sequence(app)

%Retinotopy Imaging Routine Function

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
log_fn = [app.SaveDirectoryEditField.Value filesep sprintf('%s_acquisitionlog.m',datestr(now,'mm-dd-yyyy-HH-MM'))];
logfile = fopen(log_fn,'w');

%Initialize Stimuli 
seqopts.seq_names = {'A','B','b','X','Y','y'};
seqopts.angle = [0,-45,-45,45,90,90];
seqopts.contrast = [1,1,0.4,1,1,0.4]; %rationale for choice of 40% contrast from https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6623377/
[opts] = InitializeStaticGrating(seqopts.angle,seqopts.contrast);

%Build sequences. Reccomend 500 trials of 190 frames (imaging)
%stimuli ID = [A,B,B',X,Y,Y']
seqopts.seq_prob = [0.21, 0.09, 0.14, 0.06, 0.21, 0.09, 0.14, 0.06];
%seqID: A-B, (0.21) A-Y (0.09), A-B' (0.14), A-Y' (0.06),  X-Y, X-B, X-Y',
%X-B'; so 40% probability of a low contrast stimuli
seqopts.seq_id = [ 1,2; 1,5 ; 1,3 ; 1,6 ; 4,5 ; 4,2 ; 4,6 ; 4,3 ];
N = app.cur_routine_vals.number_trials;
stim_type = [];
for i = 1:numel(seqopts.seq_prob)  
   stim_type = cat(1,stim_type,repmat(seqopts.seq_id(i,:),floor(seqopts.seq_prob(i)*N),1)); % seq_id and #_trials pairs 
end
%randomize
stim_type = stim_type(randperm(size(stim_type,1),size(stim_type,1)),:);

%pad with trial type to match total trial numbers
if size(stim_type,1)<N
    warning('padding to match number of trials');
    stim_type = cat(1,stim_type, repmat(seqopts.seq_id(1,:),N-size(stim_type,1),1));
end    

%Start listener
lh = addlistener(a,'DataAvailable', @(src,event)LogAquiredData(src,event,logfile)); % Create event listener bound to event source
a.IsContinuous = true;
a.startBackground; %Start aquisition

%get random ITI. For less jitter relative to exposure - choose interval. 
%divide by two so that it's an interval of a single wavelength
ITI = [1*round(app.cur_routine_vals.framerate/2),2*round(app.cur_routine_vals.framerate/2)];

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

    %loop through trials
    for i = 1:size(stim_type,1)            
        %Trigger camera start with a 10ms pulse 
        outputSingleScan(s,4); %deliver the trigger stimuli (4V)    
        WaitSecs(5/round(app.cur_routine_vals.framerate)); %base on exposure length
        outputSingleScan(s,0); %deliver the trigger stimuli        
 
        %wait a random interval based on exposure length
        WaitSecs(randi(ITI,1)*1/round(app.cur_routine_vals.framerate/2));
        
        %deliver stimulus                  
        showGrating(opts,stim_type(i,:),0.233,0.466)

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
    a.stop; %Stop aquiring 
    fprintf('\nSaving Log ... Please wait')
    fclose(logfile); %close this log file.     
    delete(lh); %Delete the listener for this log file
    fprintf('\nSuccesssfully completed recording.')
    recordingparameters = {app.cur_routine_vals,app.behav_cam_vals}; 
    save([app.SaveDirectoryEditField.Value,filesep sprintf('%s_stimInfo.mat',datestr(now,'mm-dd-yyyy-HH-MM'))],'stim_type','seqopts'); 
    save([app.SaveDirectoryEditField.Value,filesep sprintf('%s_recordingparameters.mat',datestr(now,'mm-dd-yyyy-HH-MM'))],'recordingparameters');   
    fprintf('Successsfully completed recording. Wrapping up...')
    Screen('closeAll')
        
catch %make sure you close the log file and delete the listened if issue
    fclose(logfile);
    delete(lh);
end


