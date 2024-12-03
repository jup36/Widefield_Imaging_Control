function digital_out_single_channel(nidq, dur_sec, amplitude)

% Specify the # of scans
scans = nidq.Rate * dur_sec;

% Specify signal_out as M X N double matrix (M: # of scans, N: # of channels)
signal_out = zeros(round(scans), 1);
signal_out (:,1) = amplitude;
signal_out = [signal_out; 0]; % ensure to end with zeros to turn it off!

write(nidq, signal_out)
end