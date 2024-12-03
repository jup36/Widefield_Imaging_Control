% nidq = daq("ni");
% nidq.Rate = 3*1e5; % can't be at max, reducing to min 2*max freq of auditory stim
% 
% nidq_out_list = ["audio", "airpuff", "water", "trigger"];
% addoutput(nidq, "Dev27", "ao0", "Voltage"); % audio
% addoutput(nidq, "Dev27", "Port0/Line8", "Digital"); % airpuff
% addoutput(nidq, "Dev27", "Port0/Line9", "Digital"); % water
% addoutput(nidq, "Dev27", "ao1", "Voltage"); % trigger
% 
% lickCh = addinput(nidq, "Dev27", "Port0/Line1", "Digital"); % lick1
% 
% start(nidq, "NumScans",round(nidq.Rate*2))
% WaitSecs(3)
% scanData = read(nidq, round(nidq.Rate*2)); 

%%
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



%%

dq = daq("ni");
% dq_out_list = ["audio", "airpuff", "water", "trigger"];
% 
% addoutput(dq, "Dev27", "ao0", "Voltage"); % audio
% addoutput(dq, "Dev27", "Port0/Line8", "Digital"); % airpuff
% addoutput(dq, "Dev27", "Port0/Line9", "Digital"); % water
% addoutput(dq, "Dev27", "ao1", "Voltage"); % trigger

addinput(dq,"Dev27","ai2","Voltage"); % add more channels as needed
% scanData = read(d,seconds(10));
dq.ScansAvailableFcn = @(src,evt) stopWhenEqualsOrExceedsFiveV(src, evt);

    %deliver stimulus (1s fixed)
    showGrating_conditioning(opts,1,5);
start(dq, "Duration", seconds(5))

while dq.Running
    pause(0.05)
    fprintf("While loop: Scans acquired = %d\n", dq.NumScansAcquired)
end
% 
% dur_sec=0.05;
% 
% % Specify the # of scans
% scans = dq.Rate * dur_sec;
% 
% % Specify signal_out as M X N double matrix (M: # of scans, N: # of channels)
% signal_out = zeros(round(scans), length(dq_out_list));
% signal_out (:, 3) = 1;
% signal_out = [signal_out; zeros(1, length(dq_out_list))]; % ensure to end with zeros to turn it off!
% 
% write(dq, signal_out)
% 
% fprintf("Acquisition has terminated with %d scans acquired\n", dq.NumScansAcquired);
% 
dq.ScansAvailableFcn = [];
dq.ScansAvailableFcn = [];


%% functions
function plotDataAvailable(src, ~)
    [data, timestamps, ~] = read(src, src.ScansAvailableFcnCount, "OutputFormat", "Matrix");
    plot(timestamps, data);
end

function stopWhenEqualsOrExceedsFiveV(src, ~)
    [data, timestamps, ~] = read(src, src.ScansAvailableFcnCount, "OutputFormat", "Matrix");
    if any(data >= 5.0)
        %disp('Detected voltage exceeds 5V: stopping acquisition')
        % stop continuous acquisitions explicitly
        src.stop()
        plot(timestamps, data)
    else
        %disp('Continuing to acquire data')
    end
end