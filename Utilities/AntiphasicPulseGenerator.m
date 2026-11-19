function nidq = AntiphasicPulseGenerator(freqHz, dutyCycle, runMode)
%ANTIPHASICPULSEGENERATOR Two 180-deg-out-of-phase pulse trains on NI counters.
%
%   nidq = AntiphasicPulseGenerator()                    % defaults: 30 Hz, 50% duty, continuous
%   nidq = AntiphasicPulseGenerator(40, 0.5, "Continuous")
%   nidq = AntiphasicPulseGenerator(20, 0.5, 5)          % 5 s finite train
%   stop(nidq)
%
% Outputs (this rig):
%   ctr0 -> PFI12 (CMOS / BNC-2110)
%   ctr1 -> PFI13 (face cam / BNC-2110)
%
% ctr1 is the logical complement of ctr0 at all duty cycles:
%   ctr0 HIGH for dutyCycle * T, then LOW
%   ctr1 LOW  for dutyCycle * T, then HIGH (duty = 1 - dutyCycle, delayed by dutyCycle * T)

if nargin < 1 || isempty(freqHz)
    freqHz = 30;
end
if nargin < 2 || isempty(dutyCycle)
    dutyCycle = 0.5;
end
if nargin < 3 || isempty(runMode)
    runMode = "Continuous";
end

freqHz = double(freqHz);
dutyCycle = double(dutyCycle);
if freqHz <= 0
    error('AntiphasicPulseGenerator:BadFreq', 'freqHz must be positive.');
end
if dutyCycle <= 0 || dutyCycle >= 1
    error('AntiphasicPulseGenerator:BadDuty', 'dutyCycle must be between 0 and 1.');
end

period_s = 1 / freqHz;
complementDuty = 1 - dutyCycle;
complementDelay_s = dutyCycle * period_s;

nidq = daq("ni");
nidq.Rate = 3e5;

ch0 = addoutput(nidq, "Dev1", "ao0", "PulseGeneration");
ch0.Frequency = freqHz;
ch0.DutyCycle = dutyCycle;

ch1 = addoutput(nidq, "Dev1", "ao1", "PulseGeneration");
ch1.Frequency = freqHz;
ch1.DutyCycle = complementDuty;

% Complement of ctr0: ctr1 goes HIGH when ctr0 goes LOW
if isprop(ch1, "InitialDelay")
    ch1.InitialDelay = complementDelay_s;
else
    warning('AntiphasicPulseGenerator:NoInitialDelay', ...
        'InitialDelay not supported on this channel; ctr0 and ctr1 may not be complementary. Verify on scope.');
end

if isnumeric(runMode) && isscalar(runMode) && runMode > 0
    start(nidq, "Duration", runMode);
elseif ischar(runMode) || isstring(runMode)
    start(nidq, char(runMode));
else
    error('AntiphasicPulseGenerator:BadRunMode', ...
        'runMode must be "Continuous", a duration string, or a positive duration in seconds.');
end

fprintf(['Antiphasic pulses: %.3f Hz, ctr0 duty %.2f, ctr1 duty %.2f ', ...
    '(ctr1 delayed %.4f s)\n'], freqHz, dutyCycle, complementDuty, complementDelay_s);

end
