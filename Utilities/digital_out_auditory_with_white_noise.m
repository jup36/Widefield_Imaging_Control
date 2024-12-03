function signal_out = digital_out_auditory_with_white_noise(nidq_rate, nidq_out_list, delays, rewarded_trial, punished_trial, tones, amplitude)
% "nidq": DataAcquisition object
% "nidq_out_list": All added nidq output channel list - analog and digital
% "nidq_ch_name": Nidq digital channel name to be activated - "airpuff" or "water"
% "dur_sec": The duration for digital line "high" in sec  

%delays is a vector that contains the delays of the task:
%1: pre_stim
%2: stim_duration
%3: outcome_delay
%4: outcome_duration
%5: outcome padding
%6: post_outcome_duration
%7: padding
%8: camera frame padding

% Specify the output channel
ch_reward = strcmpi(nidq_out_list, "water");
ch_punishment = strcmpi(nidq_out_list, "airpuff");
ch_audio = strcmpi(nidq_out_list, "audio");

% Specify the # of scans = duration of the trial
dur_sec=sum(delays);
scans = nidq_rate * dur_sec;

%time of stim
dur_pre_stim = nidq_rate *delays(1);

%time of outcome
dur_pre_outcome = nidq_rate * sum(delays(1:3));
dur_outcome = nidq_rate*delays(4);

%create white noise
white_noise=wgn(round(scans),1,-20);

%create the audiotry stim
auditory_stim_signal = make_chord(tones, amplitude, delays(2), nidq_rate);

% Specify signal_out as M X N double matrix (M: # of scans, N: # of channels)
signal_out = zeros(round(scans), length(nidq_out_list));
%audio is white noise between the tone
signal_out(:,ch_audio)=white_noise; 
%add tome
signal_out(dur_pre_stim+1:dur_pre_stim+length(auditory_stim_signal),ch_audio)=auditory_stim_signal; 

%reward or airpuff are 1 for their duration
if rewarded_trial==1
    signal_out(round(dur_pre_outcome)+1:round(dur_pre_outcome)+round(dur_outcome),ch_reward)=1;
end
if punished_trial==1
    signal_out(round(dur_pre_outcome)+1:round(dur_pre_outcome)+round(dur_outcome),ch_punishment)=1;
end

signal_out = [signal_out; zeros(1, length(nidq_out_list))]; % ensure to end with zeros to turn it off!

end
