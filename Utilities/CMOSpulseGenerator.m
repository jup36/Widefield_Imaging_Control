% Initialize nidaq object for CMOS pulse generation
app.nidq_cmos = daq("ni");
app.nidq_cmos.Rate = 3*1e5; % 300KHz
ch_cmos = addoutput(app.nidq_cmos, "Dev1", 'ctr0', "PulseGeneration"); % PFI12 on BNC-2110
ch_cmos.Frequency = 30;
ch_cmos.DutyCycle = 0.65;
start(app.nidq_cmos, "Continuous");


stop(app.nidq_cmos);

