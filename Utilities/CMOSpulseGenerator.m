% Initialize nidaq object for CMOS pulse generation
clear
app.nidq_cmos = daq("ni");
app.nidq_cmos.Rate = 3*1e5; % 300KHz
ch_cmos = addoutput(app.nidq_cmos, "Dev1", 'ctr0', "PulseGeneration"); % PFI12 on BNC-2110
ch_cmos.Frequency = 60;
ch_cmos.DutyCycle = 0.95;
start(app.nidq_cmos, "Continuous");


stop(app.nidq_cmos);

% 
% %%% code with exact number of pulses
% % Initialize the DAQ session
% clear
% app.nidq_cmos = daq("ni"); 
% 
% % 1. Create a dummy Analog Input channel to govern hardware timing
% % (Use any open physical pin on Dev1, like 'ai0')
% addinput(app.nidq_cmos, "Dev1", "ai0", "Voltage"); 
% 
% % 2. Add your pulse generation counter channel
% ch_cmos = addoutput(app.nidq_cmos, "Dev1", 'ctr0', "PulseGeneration"); % PFI12 on BNC-2110 
% ch_cmos.Frequency = 60; 
% ch_cmos.DutyCycle = 0.95; 
% 
% % 3. Calculate target window time based on desired pulse count
% numPulses = 10;                  % Exact number of pulses you want
% durationInSeconds = numPulses / ch_cmos.Frequency; % E.g., 120 / 60 = 2 seconds
% 
% % 4. Set background scan rate for the timing-governing analog input 
% app.nidq_cmos.Rate = 3*1e5;       % 10 kHz scan rate 
% 
% % 5. Pass "Duration" directly into start() as an ARGUMENT, not a property
% start(app.nidq_cmos, "Duration", seconds(durationInSeconds)); 
% 
% % 6. Wait until the hardware completes its run before letting code move on
% wait(app.nidq_cmos); 
