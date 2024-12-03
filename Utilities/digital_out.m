function digital_out(nidq, nidq_out_list, nidq_ch_name, dur_sec, amplitude)
% "nidq": DataAcquisition object
% "nidq_out_list": All added nidq output channel list - analog and digital
% "nidq_ch_name": Nidq digital channel name to be activated - "airpuff" or "water"
% "dur_sec": The duration for digital line "high" in sec  

% Specify the output channel
ch_index = strcmpi(nidq_out_list, nidq_ch_name);

% Specify the # of scans
scans = nidq.Rate * dur_sec;

% Specify signal_out as M X N double matrix (M: # of scans, N: # of channels)
signal_out = zeros(round(scans), length(nidq_out_list));
signal_out(:, ch_index) = amplitude;
signal_out = [signal_out; zeros(1, length(nidq_out_list))]; % ensure to end with zeros to turn it off!

write(nidq, signal_out)
end

% function digital_out(nidq, nidq_out_list, nidq_ch_name, dur_sec)
% % "nidq": DataAcquisition object
% % "nidq_out_list": All added nidq output channel list - analog and digital
% % "nidq_ch_name": Nidq digital channel name to be activated - "airpuff" or "water"
% % "dur_sec": The duration for digital line "high" in sec  
% 
% % Specify the output channel
% ch_index = strcmpi(nidq_out_list, nidq_ch_name);
% 
% % Specify the # of scans
% scans = nidq.Rate * dur_sec;
% 
% % Specify signal_out as M X N double matrix (M: # of scans, N: # of channels)
% signal_out = zeros(round(scans), length(nidq_out_list));
% signal_out(:, ch_index) = 1;
% signal_out = [signal_out; zeros(1, length(nidq_out_list))]; % ensure to end with zeros to turn it off!
% 
% write(nidq, signal_out)
% end

