
%% Initialize nidq
nidq_vid = daq("ni");
nidq_vid.Rate = 3*1e5; % 300KHz
ch_pulse = addoutput(nidq_vid, "Dev27", 'ctr0', "PulseGeneration");
ch_pulse.Frequency = 100; % 100 Hz
ch_pulse.DutyCycle = 0.25;

nidq = daq("ni");
nidq.Rate = 3*1e5; % can't be at max, reducing to min 2*max freq of auditory stim

addoutput(nidq, "Dev27", "Port0/Line8", "Digital"); % airpuff
addoutput(nidq, "Dev27", "Port0/Line9", "Digital"); % water
addoutput(nidq, "Dev27", "ao1", "Voltage"); % trigger

nidq_out_list=["airpuff","water","trigger"];

%% Launch camera
recording_dur = 60; % in sec

% Launch the python script that turns on the beh camera, and start generating camera pulses
cmd = sprintf('python %s %d && exit &', ...
    'C:\Users\mouse1\Documents\GitHub\pySpinCapture\cameraCapture2camsPulseTest.py', recording_dur);
system(cmd);
WaitSecs(3)
start(nidq_vid, "Continuous"); 

%% Deliver air puff

dur_airpuff=0.04;

% Specify the # of scans
scans = round(nidq.Rate * dur_airpuff);

for t=1:4
WaitSecs(2)
% Specify signal_out as M X N double matrix (M: # of scans, N: # of channels)
signal_out = zeros(round(scans), length(nidq_out_list));
signal_out (:,1) = 1;
signal_out = [signal_out; zeros(1, length(nidq_out_list))]; % ensure to end with zeros to turn it off!

write(nidq, signal_out)
end

%% Deliver water

dur_trial=0.05;

% Specify the # of scans
scans = round(nidq.Rate * dur_trial);

for t=1:10
WaitSecs(2)
% Specify signal_out as M X N double matrix (M: # of scans, N: # of channels)
signal_out = zeros(round(scans), length(nidq_out_list));
signal_out (:,2) = 1;
signal_out = [signal_out; zeros(1, length(nidq_out_list))]; % ensure to end with zeros to turn it off!

write(nidq, signal_out)
end




%%
stop(nidq_vid); 
