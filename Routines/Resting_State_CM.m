function [opts_vars, opts_vals] = Resting_State_CM(mouse,experimenter,type)

% All routines for Widefield Imaging Aquisition must follow this format

%Define types of options for the routine 
% @Values: specific list of usable values
% @Editable: If not edible, will not show up in edit configuration dialog

%Imaging Options
opts_vars(1) = struct('Name','exposure_duration','Type','scalar','Values',[],'Label','Exposure','Editable',1); 
opts_vars(2) = struct('Name','framerate','Type','scalar','Values',[],'Label','Framerate','Editable',0); 
opts_vars(3) = struct('Name','recording_duration','Type','scalar','Values',[],'Label','Duration','Editable',1); 

%Nidaq Aquisition Info
opts_vars(4) = struct('Name','analog_in_rate','Type','scalar','Values',[],'Label','AI-Rate','Editable',1); 
opts_vars(5) = struct('Name','analog_out_rate','Type','scalar','Values',[],'Label','AO-Rate','Editable',1); 
opts_vars(6) = struct('Name','digital_in_rate','Type','scalar','Values',[],'Label','DI-Rate','Editable',1); 
opts_vars(7) = struct('Name','digital_out_rate','Type','scalar','Values',[],'Label','D0-Rate','Editable',1); 

%Directory Info
opts_vars(8) = struct('Name', 'rec_date', 'Type', 'char', 'Values', [], 'Label', 'RecDate','Editable',0); 
opts_vars(9) = struct('Name', 'options_filename', 'Type', 'char', 'Values', [], 'Label', 'OptionsFilename','Editable',0); 
opts_vars(10) = struct('Name', 'acquired_data_filename', 'Type', 'char', 'Values', [], 'Label', 'DataFilename','Editable',0); 
opts_vars(11) = struct('Name', 'mouse', 'Type', 'char', 'Values', [], 'Label', 'mouse','Editable',0); 
opts_vars(12) = struct('Name', 'experimenter', 'Type', 'char', 'Values', [], 'Label', 'Experimenter','Editable',0); 
opts_vars(13) = struct('Name', 'experiment_type', 'Type', 'char', 'Values', [], 'Label', 'ExperimentType','Editable',0); 

%Define default values 

%Imaging Options
opts_vals.exposure_duration = 20;  %Camera Exposure in ms
opts_vals.framerate =1000/opts_vals.exposure_duration; %Frame rate
opts_vals.recording_duration = 100; %Total duration of the recording in seconds

%Nidaq Aquisition Info
opts_vals.analog_in_rate = 1000; %samples/sec
opts_vals.analog_out_rate = 1000; %samples/sec
opts_vals.digital_in_rate = 1000; %samples/sec
opts_vals.digital_out_rate = 1000; %samples/sec

%Directory Info
opts_vals.rec_date = datestr(datetime('Now','Format','dd-MMM-uuuu HH:mm:ss'));
opts_vals.options_filename = sprintf('%s-OptsFile.mat',mouse);
opts_vals.acquired_data_filename = sprintf('%s-AquiredData.mat',mouse);
opts_vals.mouse = mouse; 
opts_vals.experimenter = experimenter;
opts_vals.experiment_type = type;

end
