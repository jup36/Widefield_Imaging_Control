function audio_out(nidq, nidq_out_list, signal)
% "nidq": DataAcquisition object
% "nidq_out_list": All added nidq output channel list - analog and digital
% "signal": (premade) Audio signal to output

% Specify the output channel
ch_index = strcmpi(nidq_out_list, "audio");

% Specify signal_out as M X N double matrix (M: # of scans, N: # of channels)
signal_out = zeros(length(signal), length(nidq_out_list));
signal_out(:, ch_index) = signal;
write(nidq, signal_out)
end