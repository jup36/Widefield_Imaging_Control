

%% Load the data
clear
log_fn = 'acquisitionlog.m';
completelog = fopen(log_fn,'r');
[data,count] = fread(completelog,[9,inf],'double');
s = data(1,:);
figure 
hold on
count = 1;
for i = 2:size(data,1)
    subplot(5,2,count)
    ch = data(i,:);
    plot(s,ch)
    count= count+1;
end
fclose(completelog);


%Plot the data

% %ANALOG MAPPING
% ai0 - PIezo
% ai1 - trigger ready
% ai2 - Frame readout
% ai3 - Exposure out
% ai4 - Analog Output 0 (Speaker)
% ai5 - Analog Output 1 (Camera Trigger Start) 
% ai6 - Photodiode
% ai7 - output of DO0.5 (airpuff 1 (front) - negative, airpuff 2 (top) - positive)







