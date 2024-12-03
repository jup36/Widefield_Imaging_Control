nidq = daq("ni");
nidq.Rate = 3*1e5; % can't be at max, reducing to min 2*max freq of auditory stim

nidq_out_list = ["audio", "trigger"];
addoutput(nidq, "Dev1", "ao0", "Voltage"); % audio
addoutput(nidq, "Dev1", "ao1", "Voltage"); % trigger

% CMOS pulses test loop
for i = 1:5
    digital_out(nidq, nidq_out_list, "trigger", 5/30, 4)
    fprintf('Begining Recording %d sequence...\n', i);
    WaitSecs(70)
end

%% Test pulse generation for faceCam and CMOS capture  
% Create nidq for camera pulses
nidq_faceCam = daq("ni");
nidq_faceCam.Rate = 3*1e5; % 300KHz
ch_faceCam = addoutput(nidq_faceCam, "Dev1", 'ctr1', "PulseGeneration"); % PFI13 on BNC-2110
ch_faceCam.Frequency = 200; % 500 Hz %also hard coded in Camera script, not controlled here
ch_faceCam.DutyCycle = 0.5;
start(nidq_faceCam, "Continuous"); % Run pulsing for behCam continuously, and stop it at the end of the trial
stop(nidq_faceCam);

%% CMOS pulses
nidq_cmos = daq("ni");
nidq_cmos.Rate = 3*1e5; % 300KHz
ch_cmos = addoutput(nidq_cmos, "Dev1", 'ctr0', "PulseGeneration"); % PFI12 on BNC-2110
ch_cmos.Frequency = 40; 
ch_cmos.DutyCycle = 0.7;
start(nidq_cmos, "Duration", 10); % Run pulsing for behCam continuously, and stop it at the end of the trial
stop(nidq_cmos);

% CMOS pulses test loop
for i = 1:10
    start(nidq_cmos, "continuous"); % 
    fprintf('Begining Recording %d sequence...\n', i);
    WaitSecs(120)
    stop(nidq_cmos)
    WaitSecs(10)
end

%% Test python code for faceCam capture
batchFilePath = "C:\Users\buschmanlab\Documents\pySpinCapture\run_faceCam_capture.bat"; % C:\Users\buschmanlab\Documents\pySpinCapture\cameraCaptureFaceCamPulse.py
cmd = sprintf('"%s" %d %s %d && exit &', batchFilePath, 20, "mouse1", 1);

system(cmd);

%% Test tone generation
% two tones
nidq_out_list = ["audio", "trigger"];
tone_table=[1000, 14000, 80000; 5000, 16000, 40000]; %[2093, 14000, 80000; 3951, 16000, 40000];
stim_duration = 2;
amplitude=1; %10V output for speaker

tone1 = digital_out_stim_only(nidq.Rate, nidq_out_list, stim_duration, tone_table(1,:), amplitude);
tone2 = digital_out_stim_only(nidq.Rate, nidq_out_list, stim_duration, tone_table(2,:), amplitude);

preload(nidq, tone2)
start(nidq, "RepeatOutput")
WaitSecs(stim_duration);
stop(nidq);








