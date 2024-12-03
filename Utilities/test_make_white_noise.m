d=daq("ni");
d.Rate = 3*1e5;
addoutput(d, "Dev27", "ao0", "Voltage"); % audio

nidq = daq("ni");
nidq.Rate = 3*1e5; % can't be at max, reducing to min 2*max freq of auditory stim
nidq_out_list = ["audio","airpuff", "water","trigger"];
addoutput(nidq, "Dev27", "ao0", "Voltage"); % audio
addoutput(nidq, "Dev27", "Port0/Line8", "Digital"); % airpuff
addoutput(nidq, "Dev27", "Port0/Line9", "Digital"); % water
addoutput(nidq, "Dev27", "ao1", "Voltage"); % trigger

white_noise=wgn(floor(100*d.Rate),1,-10);

preload(d,white_noise)
start(d,"RepeatOutput")
pause(5)
stop(d)
preload(d,white_noise)
start(d,"RepeatOutput")
pause(5)
stop(d)