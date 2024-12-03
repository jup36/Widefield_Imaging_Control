

tone_table=[2093, 14000, 80000; 2794, 18000, 60000; 3951, 16000, 40000];

for i=1:3
    signalData = make_chord(tone_table(i,:), 0.5, 1, nidq);
    audio_out(nidq, nidq_out_list, signalData);
end


