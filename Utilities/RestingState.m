%% Resting State

% Written by Camden MacDowell 2018
% This code synchonizes the capturing of movement data (piezo) with the
% Camera aquisition. It also blinks an LED at the start and 
% every minute for timing of an external video camera if desired. 

% Micromanager bsh: 

%% Set Recording Information
clear 
clc

rootdir = uigetdir('C:\Users\mouse8\Documents\WIDEFIELD\Data'); %saving directory path
mouse = input('Please input mouse number','s'); %mouse number
d = datetime('today');
savedir = [rootdir filesep sprintf('Logs-RestingState-%s',mouse)];
if ~exist(savedir,'dir')
    mkdir(savedir);
end
log_fnbase = [savedir filesep sprintf('%s-%s-RestingState-log',mouse,d)];

%% Initialize Options 
opts.filename = [savedir filesep sprintf('%s-%s-OptsFile.mat',mouse,d)];
opts.filenametiming = [savedir filesep sprintf('%s-%s-TimingFile.mat',mouse,d)];
opts.AnalogInRate = 1000;
opts.AnalogOutRate = 1000; %For the camera trigger
opts.DigitalOutRate = 1000; %For LED blink
opts.RecDate = datetime('now'); 
opts.exposuretime = 75; %in ms
opts.framerate = 1000/opts.exposuretime;
opts.pause = 2;  %s Pause between start of aquisition (log file) and then grabbing resting state. 
opts.recDur = 60; %s of recording duration 
opts.numRec = 1; %number of recording sessions to capture (~10sec pause between recs)
opts.saveDelay = 1000; %MS DELAY TO LET THE CAMERA SAVE OFF THE VIDEO
opts.EndRecDelay = 20; %s delay to save off the log file between recs.  
opts.numFrames = ceil(((opts.recDur*1000)-opts.saveDelay)/opts.exposuretime);
opts.TotalEstimatedDuration = ((opts.recDur)*opts.numRec)/60; %in minutes

% Ceate analog input vairable to save mapping
opts.AnalogInputMaps{1} = 'ai0 - Piezo';
opts.AnalogInputMaps{2} = 'ai1 - trigger ready';
opts.AnalogInputMaps{3} = 'ai2 - Frame readout';
opts.AnalogInputMaps{4} = 'ai3 - Exposure out';
opts.AnalogInputMaps{5} = 'ai4 - Analog Output 0 (Speaker)';
opts.AnalogInputMaps{6} = 'ai5 - Analog Output 1 (Camera Trigger Start)';
opts.AnalogInputMaps{7} = 'ai6 - Photodiode';
opts.AnalogInputMaps{8} = 'ai7 - output of DO0.5 (LED)';

%% Initalize Nidaq Session and Recording Opts. 

%Analog Aquisition %See end of code for analog mapping
a = daq.createSession('ni');
a.addAnalogInputChannel('Dev1',[0,1,2,3,4,5,6,7],'Voltage')
a.Rate = opts.AnalogInRate;

%Analog Output (for trigger and speaker)
s = daq.createSession('ni');
s.Rate = opts.AnalogOutRate;
s.addAnalogOutputChannel('Dev1','ao0','Voltage')
s.addAnalogOutputChannel('Dev1','ao1','Voltage')

%Digital Output (for LED blinking sync with camera)
d = daq.createSession('ni');
d.Rate = opts.DigitalOutRate ;
d.addDigitalChannel('Dev1', 'Port0/Line3', 'OutputOnly'); % LED blink

%Make LED duration
LEDdur = 0.02; %sec


% Save opts file and stimOrder
fprintf('\tSaving Opts Information \n')
save(opts.filename,'opts');

%% Tell the experimenter frame and trial info to set on imaging rig
% At this point the experimenter needs to: 
%1) Input the number of trials to capture for each trial into the recording 
% bash script on micromanager on the imaging computer 
%2) Change the number of frames to capture for each trial. 

fprintf('\tIMPORTANT: Double check that the following are mirrored in uManager\n')
fprintf('\tExposure Time:%d ms\n',opts.exposuretime);
fprintf('\tNumber of Recordings:%d\n',opts.numRec);
fprintf('\tDuration of each Recording:%d\n',opts.recDur);
fprintf('\tNumber of Frames per Trial:%d\n',opts.numFrames);
fprintf('\tMouse number: %s\n',mouse);
fprintf('\t...\n')
fprintf('\tEstimated Duration of Recording: ~%g min\n', opts.TotalEstimatedDuration);
fprintf('\t...\n')
fprintf('\tIf the above is correct, press ENTER. Otherwise press CTRL-C\n');

pause(); 

fprintf('\tWhen ready, begin recording on micro-manager, then press ENTER\n')
%Now you can transfer the animal in with the blank screen and begin
%recording
pause();

%% Begin Recording
  
%Create and open the log file
log_fn = sprintf('%s.mat',log_fnbase);
logfile = fopen(log_fn,'w');

%set the listener to log data
lh = addlistener(a,'DataAvailable', @(src,event)logData_CM(src,event,logfile));
a.IsContinuous = true;
a.startBackground; %Start background aquisition 
WaitSecs(2) %Pause for 3 seconds prior to triggering first trial


%WaitSecs(opts.pause) %Pause for 3 seconds prior to triggering first trial 
    
    
for cur_rec = 1:opts.numRec
    fprintf('\n\tStarting Rec %d or %d\n',cur_rec,opts.numRec) 

    %Get start timestamp
    timestamp(1,cur_rec) = datetime('now');
    tic; %Start timer to make sure that each recording is the exact same length
      
    %Trigger camera start with a 10ms pulse
    outputSingleScan(s,[0 4]); %deliver the trigger stimuli
    WaitSecs(0.01);
    outputSingleScan(s,[0 0]); %deliver the trigger stimuli

    %Pulse the LED at the begining 
    d.outputSingleScan(1)
    WaitSecs(LEDdur);
    d.outputSingleScan(0);

 
    %wait until tock reaches desired rec duration
    while(toc<opts.recDur)
        continue
    end
     
    %Pulse the LED at the end 
    d.outputSingleScan(1)
    WaitSecs(LEDdur);
    d.outputSingleScan(0);
    
    
    %Get end timestamp
    timestamp(2,cur_rec) = datetime('now');
end
%Pulse LED TWICE TO SIGNAL DONE
d.outputSingleScan(1)
WaitSecs(LEDdur);
d.outputSingleScan(0); 
WaitSecs(LEDdur);
d.outputSingleScan(1)
WaitSecs(LEDdur);
d.outputSingleScan(0); 

pause(20)
a.stop; %Stop aquiring 

fprintf('Saving Log ... Please wait\n')
fclose(logfile); %close this log file. 
delete(lh) %Delete the listener for this log file


timingdata.timestamp = timestamp;
fprintf('\tSaving timing info \n')
save(opts.filenametiming,'timingdata');
fprintf('Remember to turn off behavioral recording camera!! \n',cur_rec)

% %ANALOG MAPPING
% ai0 - Piezo
% ai1 - trigger ready
% ai2 - Frame readout
% ai3 - Exposure out
% ai4 - Analog Output 0 (Speaker)
% ai5 - Analog Output 1 (Camera Trigger Start) 
% ai6 - Photodiode
% ai7 - output of DO0.5 (airpuff 1 (front) - negative, airpuff 2 (back) - positive)












