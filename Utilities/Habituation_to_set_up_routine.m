%Habituation code: white noise and grey background
clear all;

Habituation_dur=2;  %in minutes
Habituation_dur=Habituation_dur*60; %in seconds
recording_dur=Habituation_dur;
%white_noise_dur=30; %in sec
%dur_drop=0.02;

trial_dur = 8; % in sec
spout_in_dur=5;

GIVE_REWARD = 1 ; %give reward on day 2
RETRACTRABLE = 1; %spouts retract on day 3
OPERANT = 1; %must lick to get the reward on day 4
if OPERANT ==1
    GIVE_REWARD=0;
end

%% Initialize nidq
nidq_vid = daq("ni");
nidq_vid.Rate = 3*1e5; % 300KHz
ch_pulse = addoutput(nidq_vid, "Dev27", 'ctr0', "PulseGeneration");
ch_pulse.Frequency = 100; % 100 Hz
ch_pulse.DutyCycle = 0.25;

% %%Intialize screen
% stimopts.angle = [0,45,90];
% stimopts.contrast = [0.4,0.4,0.4]; %rationale for choice of 40% contrast from https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6623377/
% [opts] = InitializeStaticGrating_blue(stimopts.angle,stimopts.contrast);

nidq = daq("ni");
nidq.Rate = 3*1e5; % can't be at max, reducing to min 2*max freq of auditory stim

nidq_out_list = ["audio", "airpuff", "water", "trigger"];
addoutput(nidq, "Dev27", "ao0", "Voltage"); % audio
addoutput(nidq, "Dev27", "Port0/Line8", "Digital"); % airpuff
addoutput(nidq, "Dev27", "Port0/Line9", "Digital"); % water
addoutput(nidq, "Dev27", "ao1", "Voltage"); %rigger

% signal_out = white_noise_only(nidq.Rate, nidq_out_list, white_noise_dur);

%% create an Arduino object for lick, water and air puff
dui = serialport("COM4", 9600);
configureTerminator(dui,"CR/LF");
dui.UserData=struct("Data",[],"Count",1);
configureCallback(dui,"terminator",@readSerialData)

%% Loop (if day 2 of

% Launch the python script that turns on the beh camera, and start generating camera pulses
cmd = sprintf('python %s %d && exit &', ...
    'C:\Users\mouse1\Documents\GitHub\pySpinCapture\cameraCapture2camsPulseTest.py', recording_dur);
system(cmd);
WaitSecs(5)
start(nidq_vid, "Continuous");
if RETRACTRABLE==1
    write(dui, "S", "char" ); %initial set up, further from the mouse
else
    write(dui, "L", "char" ); %initial set up, closer to the mouse
end

for i=1:floor(Habituation_dur/trial_dur)

    %     preload(nidq, signal_out) %no white noise
    %     start(nidq)
    tic
    if RETRACTRABLE==1
        write(dui, "I", "char" );
    end
    if GIVE_REWARD==1 %case when we give reward freely
        for j=1:3
            WaitSecs(1);
            write(dui, "D", "char" ); %doesn't matter what we send, just not P or R
        end
    elseif OPERANT == 1 %case when mouse must lick for reward (make sureto load 1s interRewardInterval
        write(dui, "R", "char" );
    end
    while toc<spout_in_dur
    end
    if RETRACTRABLE==1
        write(dui, "O", "char" );
    end
    while toc<trial_dur
    end
    %     stop(nidq);

    fprintf('\n%d out of %d\n', i, floor(Habituation_dur/trial_dur));

end
WaitSecs(trial_dur);
stop(nidq_vid)