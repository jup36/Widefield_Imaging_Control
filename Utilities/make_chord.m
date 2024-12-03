function signalData = make_chord(freq_mix, amplitude, dur_sec, nidq_rate)

sample_rate = round(nidq_rate);

T=1:sample_rate; %length

for i=1:length(freq_mix)
    freq=freq_mix(i);
    signalData_ind(i,:) = amplitude.*sin(T*2*pi/(length(T)/freq));
end
signalData = sum(signalData_ind / length(freq_mix),1);
signalData = signalData(1:sample_rate);

signalData=repmat(signalData,[1 ceil(dur_sec)]);

if round(dur_sec*sample_rate)>size(signalData,2)
    signalData=signalData(1:round(dur_sec*sample_rate)-1);
else
    signalData=signalData(1:round(dur_sec*sample_rate));
end

end