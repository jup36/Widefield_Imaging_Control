function [opts_vars, opts_vals] = deliver_random_visualstim_and_reward_config(mouse,experimenter,type)

% Random single-grating presentations and reward drops during widefield recording.
% Set number_visual_trials and number_reward_trials; inter-event spacing uses
% Gaussian intervals (mean/std/min). Stimulus pool from flex_stim_definition.

%General Options
opts_vars(1) = struct('Name','routine_name','Type','char','Values',[],'Label','AssociatedRoutine','Editable',1);

%Imaging Options
opts_vars(2) = struct('Name','exposure_duration','Type','scalar','Values',[],'Label','Exposure (ms)','Editable',1);
opts_vars(3) = struct('Name','framerate','Type','scalar','Values',[],'Label','Framerate','Editable',0);
opts_vars(4) = struct('Name','recording_duration','Type','scalar','Values',[],'Label','Duration (s)','Editable',1);

%Nidaq Aquisition Info
opts_vars(5) = struct('Name','analog_in_rate','Type','scalar','Values',[],'Label','AI-Rate (hz)','Editable',1);
opts_vars(6) = struct('Name','analog_out_rate','Type','scalar','Values',[],'Label','AO-Rate (hz)','Editable',1);
opts_vars(7) = struct('Name','digital_in_rate','Type','scalar','Values',[],'Label','DI-Rate (hz)','Editable',1);
opts_vars(8) = struct('Name','digital_out_rate','Type','scalar','Values',[],'Label','D0-Rate (hz)','Editable',1);

%Directory Info
opts_vars(9) = struct('Name', 'rec_date', 'Type', 'char', 'Values', [], 'Label', 'RecDate','Editable',0);
opts_vars(10) = struct('Name', 'options_filename', 'Type', 'char', 'Values', [], 'Label', 'OptionsFilename','Editable',0);
opts_vars(11) = struct('Name', 'acquired_data_filename', 'Type', 'char', 'Values', [], 'Label', 'DataFilename','Editable',0);
opts_vars(12) = struct('Name', 'mouse', 'Type', 'char', 'Values', [], 'Label', 'mouse','Editable',0);
opts_vars(13) = struct('Name', 'experimenter', 'Type', 'char', 'Values', [], 'Label', 'Experimenter','Editable',0);
opts_vars(14) = struct('Name', 'experiment_type', 'Type', 'char', 'Values', [], 'Label', 'ExperimentType','Editable',0);

%Input/Output Mapping Info
opts_vars(15) = struct('Name','expose_out_chan','Type','scalar','Values',[0,1,2,3],'Label','Exposure Out Chan','Editable',1);
opts_vars(16) = struct('Name','frame_readout_chan','Type','scalar','Values',[0,1,2,3],'Label','Frame Readout Chan','Editable',1);
opts_vars(17) = struct('Name','trigger_ready_chan','Type','scalar','Values',[0,1,2,3],'Label','Trigger Ready Chan','Editable',1);
opts_vars(18) = struct('Name','photodiode_chan','Type','scalar','Values',[0,1,2,3],'Label','Photodiode Chan','Editable',1);
opts_vars(19) = struct('Name','trigger_out_chan','Type','scalar','Values',[0,1,2,3],'Label','Tigger Out Chan','Editable',1);

% Stimulus pool and timing
opts_vars(20) = struct('Name','flex_stim_definition','Type','char','Values',[],'Label','Flex stims (name,angle,ctr)','Editable',1);
opts_vars(21) = struct('Name','flex_stim_duration','Type','scalar','Values',[],'Label','Grating on (s)','Editable',1);
opts_vars(22) = struct('Name','number_visual_trials','Type','scalar','Values',[],'Label','Number visual trials','Editable',1);
opts_vars(23) = struct('Name','number_reward_trials','Type','scalar','Values',[],'Label','Number reward trials','Editable',1);
opts_vars(24) = struct('Name','visual_interval_mean_s','Type','scalar','Values',[],'Label','Visual interval mean (s)','Editable',1);
opts_vars(25) = struct('Name','visual_interval_std_s','Type','scalar','Values',[],'Label','Visual interval SD (s)','Editable',1);
opts_vars(26) = struct('Name','visual_interval_min_s','Type','scalar','Values',[],'Label','Visual interval min (s)','Editable',1);
opts_vars(27) = struct('Name','reward_interval_mean_s','Type','scalar','Values',[],'Label','Reward interval mean (s)','Editable',1);
opts_vars(28) = struct('Name','reward_interval_std_s','Type','scalar','Values',[],'Label','Reward interval SD (s)','Editable',1);
opts_vars(29) = struct('Name','reward_interval_min_s','Type','scalar','Values',[],'Label','Reward interval min (s)','Editable',1);
opts_vars(30) = struct('Name','post_reward_s','Type','scalar','Values',[],'Label','Post reward wait (s)','Editable',1);
opts_vars(31) = struct('Name','reward_serial_port','Type','char','Values',[],'Label','Reward serial port','Editable',1);

%%Define default values
opts_vals.routine_name = 'deliver_random_visualstim_and_reward';

opts_vals.exposure_duration = 33.33;
opts_vals.framerate = 1000/opts_vals.exposure_duration;
opts_vals.recording_duration = 600;

opts_vals.analog_in_rate = 1000;
opts_vals.analog_out_rate = 1000;
opts_vals.digital_in_rate = 1000;
opts_vals.digital_out_rate = 1000;

opts_vals.rec_date = datestr(datetime('Now','Format','dd-MMM-uuuu HH:mm:ss'));
opts_vals.options_filename = sprintf('%s-OptsFile.mat',mouse);
opts_vals.acquired_data_filename = sprintf('%s-AquiredData.mat',mouse);
opts_vals.mouse = mouse;
opts_vals.experimenter = experimenter;
opts_vals.experiment_type = type;

opts_vals.expose_out_chan = 0;
opts_vals.frame_readout_chan = 3;
opts_vals.trigger_ready_chan = 1;
opts_vals.photodiode_chan = 2;
opts_vals.trigger_out_chan = 1;

opts_vals.flex_stim_definition = sprintf([ ...
    'A,20,1\n' ...
    'B,80,1\n' ...
    'C,40,1\n' ...
    'D,60,1' ]);
opts_vals.flex_stim_duration = 0.5;
opts_vals.number_visual_trials = 20;
opts_vals.number_reward_trials = 15;
opts_vals.visual_interval_mean_s = 30;
opts_vals.visual_interval_std_s = 10;
opts_vals.visual_interval_min_s = 5;
opts_vals.reward_interval_mean_s = 45;
opts_vals.reward_interval_std_s = 15;
opts_vals.reward_interval_min_s = 10;
opts_vals.post_reward_s = 2;
opts_vals.reward_serial_port = 'COM4';

end
