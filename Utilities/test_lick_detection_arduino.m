clearvars a 

% Create nidq object
nidq = daq("ni");
nidq.Rate = 3*1e5; % can't be at max, reducing to min 2*max freq of auditory stim

nidq_out_list = ["audio", "airpuff", "water", "trigger"];
addoutput(nidq, "Dev27", "ao0", "Voltage"); % audio
addoutput(nidq, "Dev27", "Port0/Line8", "Digital"); % airpuff
addoutput(nidq, "Dev27", "Port0/Line9", "Digital"); % water
addoutput(nidq, "Dev27", "ao1", "Voltage"); % trigger

% create an Arduino object
a = arduino('COM4', 'uno');
waterpin = 'D2';
airpin = 'D3';
switchpin = 'D4'; 
lickpin = 'D8';

configurePin(a, lickpin,'DigitalInput')  % lickometer
configurePin(a, switchpin,'DigitalInput') % switch
configurePin(a, waterpin,'DigitalOutput') % water
configurePin(a, airpin,'DigitalOutput') % airpuff

%% Create the stims
N=100;

%Initialize Stimuli
stimopts.angle = [0,45,90];
stimopts.contrast = [0.4,0.4,0.4]; %rationale for choice of 40% contrast from https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6623377/
[opts] = InitializeStaticGrating(stimopts.angle,stimopts.contrast);
%Build sequences. Reccomend 500 trials of 190 frames (imaging)
stimopts.stim_id = [1 2 3];
stimopts.positive_stim = 3; % might need to counterbalance across mice
stimopts.negative_stim = 1; % might need to counterbalance
stimopts.neutral_stim = 2; % might need to counterbalance
stimopts.stim_prob(stimopts.positive_stim) = 1 ; %positive stim
stimopts.stim_prob(stimopts.neutral_stim) = 0 ; %neutral stim
stimopts.stim_prob(stimopts.negative_stim) = 0 ; %negative stim

%Attribute outcome
stimopts.proba_positive_stim = [0.8 0.2 0]; % [reward omission punishment]
stimopts.proba_negative_stim = [0.25 0.75 0]; % [reward omission punishment]

stim_type = [];
for i = 1:numel(stimopts.stim_prob)
    stim_type = cat(1,stim_type,repmat(stimopts.stim_id(i),floor(stimopts.stim_prob(i)*N),1));
end

%pad with trial type to match total trial numbers
while size(stim_type,1)<N
    stim_type(end+1) = stimopts.stim_id(randi(length(stimopts.stim_id)));
end

%randomize
stim_type = stim_type(randperm(size(stim_type,1),size(stim_type,1)),:);

%% Set the duration to monitor in seconds
dur_stim = 5; % Monitor for 10 seconds
dur_drop=0.1;
dead_time_lick=0.2; %we would incrase that to 500ms to make sure we have a good read of the stim pre-lick


%% start the loop
for n=1:5

    WaitSecs(2)
    values = [];
    value=[];
    lick_flag=0;

    % Start the timer
    tic;
    start_of_showGrating_conditioning(opts,stim_type(n)); %strat stim

    disp('start loop')
    while toc <= dur_stim
        %monitor the lick port
        if toc > dead_time_lick %don't detect licks before dead time (to make sure they see the stim)
            %Read the digital input value
            value = readDigitalPin(a, lickpin);
            values=[values; value];
            if value==1 && lick_flag==0
                %deliver the drop
                writeDigitalPin(a,waterpin,1)
                WaitSecs(dur_drop)
                writeDigitalPin(a,waterpin,0)
                lick_flag=0;
            end
        end
        pause(0.05);
    end
    Screen('Flip', opts.window);
    figure
    plot(values)
end

%% old stuff
% flush(nidq)

% %Specify the # of scans
% scans = round(nidq.Rate * dur_drop);
% %Specify signal_out as M X N double matrix (M: # of scans, N: # of channels)
% signal_out = zeros(round(scans), length(nidq_out_list));
% signal_out (:, 2) = 1;
% signal_out = [signal_out; zeros(1, length(nidq_out_list))]; % ensure to end with zeros to turn it off


% Main loop to monitor the digital input channel
% values = [];
% value=[];
% lick_flag=0;
% Read the digital input value
%     value = readDigitalPin(a, lickpin);
%if value==1
%    lick_flag=1;
%    write(nidq, signal_out)
%end
%     values = [values; value];
% Display the value
%     disp(['Digital Input Value: ' num2str(value)]);

% Pause for a short duration
%     pause(0.05);


% dq_out_list = ["audio", "airpuff", "water", "trigger"];
%
% addoutput(dq, "Dev27", "ao0", "Voltage"); % audio
% addoutput(dq, "Dev27", "Port0/Line8", "Digital"); % airpuff
% addoutput(dq, "Dev27", "Port0/Line9", "Digital"); % water
% addoutput(dq, "Dev27", "ao1", "Voltage"); % trigger

% figure; hold on;
% plot(values, 'r')


% dq = daq("ni");
% % Create an Arduino object
% a = arduino('COM4', 'uno');
% lickpin = 'D8';
% configurePin(a, lickpin,'DigitalInput')  % lickometer


%
% lickCh = addinput(nidq, "Dev27", "Port0/Line1", "Digital"); % lick1
%
% start(nidq, "NumScans",round(nidq.Rate*2))
% WaitSecs(3)
% scanData = read(nidq, round(nidq.Rate*2));
%


