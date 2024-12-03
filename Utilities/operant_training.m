%Operant training with white noise and grey background

clear all

Habituation_dur=20;  %in minutes
Habituation_dur=Habituation_dur*60; %in seconds
% white_noise_dur=30; %in sec
% dur_drop=0.05;
time_off_reward=3;

%% Initialize nidq video
nidq_vid = daq("ni");
nidq_vid.Rate = 3*1e5; % 300KHz
ch_pulse = addoutput(nidq_vid, "Dev27", 'ctr0', "PulseGeneration");
ch_pulse.Frequency = 100; % 100 Hz
ch_pulse.DutyCycle = 0.25;

recording_dur = white_noise_dur; % in sec

%% Intialize screen
stimopts.angle = [0,45,90];
stimopts.contrast = [0.4,0.4,0.4]; %rationale for choice of 40% contrast from https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6623377/
[opts] = InitializeStaticGrating_blue(stimopts.angle,stimopts.contrast);

%% Intialize nidq 
nidq = daq("ni");
nidq.Rate = 3*1e5; % can't be at max, reducing to min 2*max freq of auditory stim

nidq_out_list = ["audio", "airpuff", "water", "trigger"];
addoutput(nidq, "Dev27", "ao0", "Voltage"); % audio
addoutput(nidq, "Dev27", "Port0/Line8", "Digital"); % airpuff
addoutput(nidq, "Dev27", "Port0/Line9", "Digital"); % water
addoutput(nidq, "Dev27", "ao1", "Voltage"); %trigger

%white noise
% signal_out = white_noise_only(nidq.Rate, nidq_out_list, white_noise_dur);

%% Initialize arduino

warning('Load arduino sketch lick_switch_water_air_MR_50ms and press Enter to continue')
pause

%create the port for communication with arduino
%If interacting with a program for the arduino
%The arduino program needs to be uploaded before running the MATLAB code
dui = serialport("COM4", 9600);
configureTerminator(dui,"CR/LF");
dui.UserData=struct("Data",[],"Count",1);
configureCallback(dui,"terminator",@readSerialData)
write(dui, "O", "char" ); %doesn't matter what we send, just not P or R

%% Loop

%counts the number of licks
rewards=0;

for i=1:floor(Habituation_dur/white_noise_dur)
    %start timer
    write(dui, "O", "char" );
    % Launch the python script that turns on the beh camera, and start generating camera pulses
    cmd = sprintf('python %s %d && exit &', ...
        'C:\Users\mouse1\Documents\GitHub\pySpinCapture\cameraCapture2camsPulseTest.py', recording_dur);
    system(cmd);
    WaitSecs(3);
    start(nidq_vid, "Continuous");
        tic;
    %start white noise
%     preload(nidq, signal_out)
%     start(nidq)

    write(dui, "R", "char" );
    WaitSecs(time_off_reward);

    write(dui, "O", "char" );
    stop(nidq);
    stop(nidq_vid);
    WaitSecs(1);

    fprintf('\n%d out of %d\n', i, round(Habituation_dur/white_noise_dur));

end

rewards=sum(dui.UserData.Data==1);
airpuffs=sum(dui.UserData.Data==2);

fprintf('\nMouse received %d rewards and %d air puffs\n',rewards,airpuffs)



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the callback function to read the serial data
function readSerialData(src,~)

data = readline(src); % Read the data from Arduino
src.UserData.Data(end+1)=str2double(data);
src.UserData.Count=src.UserData.Count+1;

outcome = str2double(char(data)); % Convert the received uint8 data to a number
if outcome==1
    fprintf('Reward\n'); % Display the received value
elseif outcome==2
    fprintf('Air Puff\n'); % Display the received value
elseif outcome==3
    fprintf('Manual reward\n'); % Display the received value
end

end




%%%% old code
%% Intialize Arduino
% a = arduino('COM4', 'uno');
% waterpin = 'D2';
% airpin = 'D3';
% switchpin = 'D4'; 
% lickpin = 'D8';
% 
% configurePin(a, lickpin,'DigitalInput') % lickometer
% configurePin(a, switchpin,'DigitalInput') % switch for water
% configurePin(a, waterpin,'DigitalOutput') % water
% configurePin(a, airpin,'DigitalOutput') % airpuff




%     %listen to lick
%     while toc <= white_noise_dur
%         %monitor the lick port
%         %Read the digital input value
%         lick_logic = readDigitalPin(a, lickpin);
%         switch_logic = readDigitalPin(a, switchpin);
%         if lick_logic==1 || switch_logic==1 
%             %deliver the drop
%             writeDigitalPin(a,waterpin,1);
%             WaitSecs(dur_drop);
%             writeDigitalPin(a,waterpin,0);
%             rewards=rewards+1;
%             WaitSecs(time_off_reward);
%         end
%     end
