function signal_out = white_noise_only(nidq_rate, nidq_out_list, dur_sec)
% "nidq": DataAcquisition object
% "nidq_out_list": All added nidq output channel list - analog and digital
% "nidq_ch_name": Nidq digital channel name to be activated - "airpuff" or "water"
% "dur_sec": The duration for digital line "high" in sec  

% Specify the output channel
ch_audio = strcmpi(nidq_out_list, "audio");

% Specify the # of scans = duration of the trial
scans = nidq_rate * dur_sec;

%create white noise
white_noise=wgn(round(scans),1,-20);

% Specify signal_out as M X N double matrix (M: # of scans, N: # of channels)
signal_out = zeros(round(scans), length(nidq_out_list));
%audio is white noise the whole time
signal_out(:,ch_audio)=white_noise; 

signal_out = [signal_out; zeros(1, length(nidq_out_list))]; % ensure to end with zeros to turn it off!

%write(nidq, signal_out)
end
