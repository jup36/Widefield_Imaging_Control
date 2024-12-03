%function behCam_pulses(pulse_dur)

% Generate Voltage Signals Using NI Devices
% https://www.mathworks.com/help/daq/generate-signals-on-ni-devices-that-output-voltage.html

% Generate Non-Clocked Digital Data
% https://www.mathworks.com/help/daq/generate-non-clocked-digital-data.html   

% Generate Pulse Data on a Counter Channel
% https://www.mathworks.com/help/daq/generate-pulse-data-on-a-counter-channel.html

%% Pulse Output
% nidq = daq("ni");
% ch_pulse.Terminal % identify the terminal for the pulse output 
nidq = daq("ni");
nidq.Rate = 3*1e5; % 300KHz
ch_pulse = addoutput(nidq, "Dev27", 'ctr0', "PulseGeneration");
ch_pulse.Frequency = 500; % 500 Hz 
ch_pulse.DutyCycle = 0.25; 
pulse_dur=10;

%% Execute
disp('start nidq')
%disp(nidq.Rate)
%disp(pulse_dur*nidq.Rate)
start(nidq, "NumScans", pulse_dur*nidq.Rate);
% DON'T DO WAITSECS HERE! IT KEPT PULSING GOING FOR SOME REASON!

%% Digital Output
% nidq_dg = daq("ni"); 
% nidq_dg.Rate = 3*1e5; % 300K Hz
%nidq_out_list = ["audio", "airpuff", "water","trigger"]; 
% addoutput(nidq_dg, "Dev27", "ao0", "Voltage"); % audio
% addoutput(nidq_dg, "Dev27", "Port0/Line8", "Digital"); % airpuff
% addoutput(nidq_dg, "Dev27", "Port0/Line9", "Digital"); % water
% addoutput(nidq_dg, "Dev27", "ao1", "Voltage"); % trigger
%digital_out(nidq_dg, nidq_out_list, "airpuff", 3, 1) % Use start to initiate operations when counter output channels are configured.

