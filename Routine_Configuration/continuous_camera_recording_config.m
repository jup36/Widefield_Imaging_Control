function [opts_vars, opts_vals] = continuous_camera_recording_config(mouse,experimenter,type)

% Configuration for continuous_camera_recording routine
% All routines for Widefield Imaging Acquisition must follow this format

% Define types of options for the routine 
% @Values: specific list of usable values
% @Editable: If not editable, will not show up in edit configuration dialog

% General Options
opts_vars(1) = struct('Name','routine_name','Type','char','Values',[],'Label','AssociatedRoutine','Editable',1); 

% Imaging Options
opts_vars(2) = struct('Name','exposure_duration','Type','scalar','Values',[],'Label','Exposure (ms)','Editable',1); 
opts_vars(3) = struct('Name','framerate','Type','scalar','Values',[],'Label','Framerate','Editable',0); 
opts_vars(4) = struct('Name','recording_duration','Type','scalar','Values',[],'Label','Recording duration (s)','Editable',1); 

% Directory / Meta Info
opts_vars(5) = struct('Name', 'rec_date', 'Type', 'char', 'Values', [], 'Label', 'RecDate','Editable',0); 
opts_vars(6) = struct('Name', 'mouse', 'Type', 'char', 'Values', [], 'Label', 'mouse','Editable',0); 
opts_vars(7) = struct('Name', 'experimenter', 'Type', 'char', 'Values', [], 'Label', 'Experimenter','Editable',0); 
opts_vars(8) = struct('Name', 'experiment_type', 'Type', 'char', 'Values', [], 'Label', 'ExperimentType','Editable',0); 

% CMOS pulse control
% 1 = send CMOS pulses via app.nidq_cmos, 0 = do not send CMOS pulses
opts_vars(9) = struct('Name','use_cmos_pulses','Type','scalar','Values',[0 1],'Label','Use CMOS pulses','Editable',1);

%% Define default values 
% General Options
opts_vals.routine_name = 'continuous_camera_recording';

% Imaging Options
opts_vals.exposure_duration = 25;  % Camera exposure in ms
opts_vals.framerate = 1000/opts_vals.exposure_duration; % Frame rate
opts_vals.recording_duration = 300; % Total duration of the recording in seconds (default 5 minutes)

% Directory / Meta Info
opts_vals.rec_date = datestr(datetime('Now','Format','dd-MMM-uuuu HH:mm:ss'));
opts_vals.mouse = mouse; 
opts_vals.experimenter = experimenter;
opts_vals.experiment_type = type;

% CMOS pulse control
opts_vals.use_cmos_pulses = 0; % default: do NOT send CMOS pulses

end

