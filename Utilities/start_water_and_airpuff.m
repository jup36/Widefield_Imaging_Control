%turn on water and air puff at the start of the day
% "dur_sec": The duration for digital line "high" in sec

%Get the water and air through the tubes

%devices = daq.getDevices;
%disp(devices);
nidq = daq("ni");
nidq.Rate = 3*1e5; % can't be at max, reducing to min 2*max freq of auditory stim

addoutput(nidq, "Dev1", "Port0/Line0", "Digital"); % airpuff
addoutput(nidq, "Dev1", "Port0/Line9", "Digital"); % water
addoutput(nidq, "Dev1", "ao1", "Voltage"); % trigger

nidq_out_list=["airpuff","water","trigger"];

%% FLUSH
dur_sec=30;

% Specify the # of scans
scans = nidq.Rate * dur_sec;

% Specify signal_out as M X N double matrix (M: # of scans, N: # of channels)
signal_out = zeros(round(scans), length(nidq_out_list));
signal_out (:, 2) = 1;
signal_out = [signal_out; zeros(1, length(nidq_out_list))]; % ensure to end with zeros to turn it off!

write(nidq, signal_out)

%% Calibrate the water (remove comments to run)
dur_trial=0.05;

%Specify the # of scans
scans = round(nidq.Rate * dur_trial);

for t=1:3
    WaitSecs(2);
    %Specify signal_out as M X N double matrix (M: # of scans, N: # of channels)
    signal_out = zeros(round(scans), length(nidq_out_list));
    signal_out (:, 2) = 1;
    signal_out = [signal_out; zeros(1, length(nidq_out_list))]; % ensure to end with zeros to turn it off!

    write(nidq, signal_out)
end


