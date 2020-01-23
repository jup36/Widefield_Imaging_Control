

%% Load the data
clear
log_fn = 'acquisitionlog.m';
completelog = fopen(log_fn,'r');
w= 10000; 
[data,count] = fread(completelog,[9,200000],'double');
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
% ai0 - Analog Output 1 (Camera Trigger Start)
% ai1 - trigger ready
% ai6 - Frame readout
% ai7 - Analog Output 0 (Speaker)
% ai20 - Piezzo
% ai21 - Photodiode



%% Check frame timing

freadout_diff = data(4, :) - circshift(data(4, :), 1, 2);
histogram(freadout_diff)
tresh = 0.5*max(freadout_diff);
f_ind = freadout_diff > tresh;
f_times = s(f_ind);

f_times_diff = f_times - circshift(f_times, 1, 2);
unique(f_times_diff)
t_total = f_times(end) - f_times(1)
underFract = sum(f_times_diff < 0.0195)/numel(f_times_diff)
overFract = sum(f_times_diff > 0.0195)/numel(f_times_diff)
histogram(f_times_diff, 'BinLimits',[0.018, 0.021])







