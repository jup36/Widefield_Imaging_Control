% Generate Voltage Signals Using NI Devices
% https://www.mathworks.com/help/daq/generate-signals-on-ni-devices-that-output-voltage.html

% Generate Non-Clocked Digital Data
% https://www.mathworks.com/help/daq/generate-non-clocked-digital-data.html   

%daq.getDevices

%Digital Output
d=daq("ni");
d.Rate = 9*1e5; % 900K Hz;
% ch = addoutput(d,"Dev27",0,"Voltage");
ch_air = addoutput(d,"Dev27",'Port0/Line8',"Digital");
ch_rwd = addoutput(d,"Dev27",'Port0/Line9',"Digital");

d.Rate = 10000; % 900000;

write(d, [1 0]); % deliver the trigger stimuli
WaitSecs(1);
write(d, [0 0]); % deliver the trigger stimuli

write(d, [0 1]); % deliver the trigger stimuli
WaitSecs(1);
write(d, [0 0]); % deliver the t

%create sound wave
% A = 5;
% T = 1;
% f = 100; %2kHz
% dT = 1/(100*f);
% sound_id=0:dT:T-dT;
% sound = A*sin(sound_id*f*2*pi);

% if dT<1/s_rew.Rate
%     disp('Frequency is to high for sampling rate')
% else

% s_rew.addDigitalChannel('Dev27', 'Port0/Line9', 'OutputOnly'); 
% s_rew.addAnalogOutputChannel('Dev27', 'ao0','Voltage')

% for i = 1
%     for j=1:length(sound_id)
%         outputSingleScan(s_rew, sound(j)); %deliver the trigger stimuli
%         WaitSecs(dT);
%    end
%     %outputSingleScan(s_rew, 0); %deliver the trigger stimuli
    %WaitSecs(1);
%        WaitSecs(0.1);
%        outputSingleScan(ch, 0); %deliver the trigger stimuli
%        WaitSecs(1);
% end
% end