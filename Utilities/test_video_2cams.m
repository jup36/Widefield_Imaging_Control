
nidq_vid = daq("ni");
nidq_vid.Rate = 3*1e5; % 300KHz
ch_pulse = addoutput(nidq_vid, "Dev27", 'ctr0', "PulseGeneration");
ch_pulse.Frequency = 100; % 100 Hz
ch_pulse.DutyCycle = 0.25;

recording_dur = 120; % in sec

% Launch the python script that turns on the beh camera, and start generating camera pulses
cmd = sprintf('python %s %d && exit &', ...
    'C:\Users\mouse1\Documents\GitHub\pySpinCapture\cameraCapture2camsPulseTest.py', recording_dur);
system(cmd);
WaitSecs(3)
start(nidq_vid, "Continuous"); 
WaitSecs(recording_dur)
stop(nidq_vid);