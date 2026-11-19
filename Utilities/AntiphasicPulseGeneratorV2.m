%% 1. Initialize TWO Separate Interfaces
clear dq_counter dq_digital
dq_counter = daq("ni");
dq_digital = daq("ni");

%% 2. Configure Counter 0 (Runs natively at 1000 Hz)
masterClock = addoutput(dq_counter, "Dev1", "ctr0", "PulseGeneration");
masterClock.Frequency = 1000; % 1 kHz square wave
masterClock.DutyCycle=0.9;

%% 3. Configure Digital Outputs (Pure Digital Session)
addoutput(dq_digital, "Dev1", "port0/line1", "Digital");
addoutput(dq_digital, "Dev1", "port0/line2", "Digital");

% Since Ctr0InternalOutput ticks exactly 1000 times a second, 
% your digital execution rate MUST match it.
dq_digital.Rate = 1000; 

%% 4. SUCCESSFUL ROUTING: Clock off the counter's actual output pin
addclock(dq_digital, "ScanClock", "External", "Dev1/Ctr0InternalOutput");

%% 5. Construct Pure Digital Waveforms (Half-Frequency & Antiphased)
duration = 10000; 
totalSamples = dq_digital.Rate * duration; % 2000 total clock ticks

% To get a 500 Hz wave from a 1000 Hz clock, the signal must change every 1 tick.
% We create a perfect alternating pattern of [1; 0; 1; 0...]
pulse_500Hz_main = repmat([1; 0], totalSamples/2, 1);
pulse_500Hz_anti = repmat([0; 1], totalSamples/2, 1); % Exactly 180° inverted

outputMatrix = [pulse_500Hz_main, pulse_500Hz_anti];

%% 6. Start the System Safely
% Step A: Preload the digital array data
preload(dq_digital, outputMatrix);

% Step B: Start the digital loop (Stalls cleanly, waiting for the first ctr0 edge)
start(dq_digital, "Continuous"); 

% Step C: Start the counter. The very first 1000Hz pulse instantly triggers 
% and steps your 500Hz digital channels in perfect hardware lockstep.
start(dq_counter, "Continuous"); 

disp('System running cleanly. Execute the lines below to stop:');
disp('stop(dq_counter); stop(dq_digital);');
