% Initialize DAQ session
nidq_cmos = daq("ni");
nidq_cmos.Rate = 3 * 1e5; % 300KHz

% Add output channel for pulse generation on PFI12 (ctr0)
ch_cmos = addoutput(nidq_cmos, "Dev1", 'ctr0', "PulseGeneration"); % PFI12 on BNC-2110

% Configure pulse generation parameters
ch_cmos.Frequency = 20; % 20 Hz
ch_cmos.DutyCycle = 0.5;

% Set the duration of the pulse train (in seconds)
pulseDuration = 5; % Duration in seconds, expecting 100 pulses at 20 Hz

% Initialize pulse counter
pulseCount = 0;

% Create a listener to count the number of pulses
lh = addlistener(nidq_cmos, 'DataRequired', @(src, event) pulseCountHandler(src, event, ch_cmos.Frequency, pulseDuration, nidq_cmos));

% Start the pulse generation
start(nidq_cmos, "Duration", pulseDuration);

% The main MATLAB script continues to run other tasks
disp('Pulse generation started. Other tasks can run concurrently.');

% Wait for the task to complete
wait(nidq_cmos);

% Display the number of pulses generated
disp(['Total number of pulses generated: ', num2str(pulseCount)]);

% Clean up the listener
delete(lh);

function pulseCountHandler(~, ~, frequency, duration, nidaq)
    global pulseCount;
    pulseCount = pulseCount + frequency * duration;
    stop(nidaq); % Stops the DAQ session once the desired number of pulses has been reached
end
