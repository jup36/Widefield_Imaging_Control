function [opts_vars, opts_vals] = example_routine(mouse,experimenter,type)

% All routines for Widefield Imaging Aquisition must follow this format

%Define types of options for the routine 
% @Values: specific list of usable values
% @Editable: If not edible, will not show up in edit configuration dialog

%Imaging Options
opts_vars(1) = struct('Name','ExposureDuration','Type','scalar','Values',[],'Label','Exposure','Editable',1); 
opts_vars(2) = struct('Name','Framerate','Type','scalar','Values',[],'Label','Framerate','Editable',0); 
opts_vars(3) = struct('Name','RecordingDuration','Type','scalar','Values',[],'Label','Duration','Editable',1); 

%Nidaq Aquisition Info
opts_vars(4) = struct('Name','AnalogInRate','Type','scalar','Values',[],'Label','AI-Rate','Editable',1); 
opts_vars(5) = struct('Name','AnalogOutRate','Type','scalar','Values',[],'Label','AO-Rate','Editable',1); 
opts_vars(6) = struct('Name','DigitalOutRate','Type','scalar','Values',[],'Label','D0-Rate','Editable',1); 
opts_vars(7) = struct('Name','DigitalInRate','Type','scalar','Values',[],'Label','DI-Rate','Editable',1); 

%Directory Info
opts_vars(8) = struct('Name', 'RecDate', 'Type', 'char', 'Values', [], 'Label', 'RecDate','Editable',0); 
opts_vars(9) = struct('Name', 'OptionsFilename', 'Type', 'char', 'Values', [], 'Label', 'OptionsFilename','Editable',0); 
opts_vars(10) = struct('Name', 'AquiredDataFilename', 'Type', 'char', 'Values', [], 'Label', 'DataFilename','Editable',0); 
opts_vars(11) = struct('Name', 'mouse', 'Type', 'char', 'Values', [], 'Label', 'mouse','Editable',0); 
opts_vars(12) = struct('Name', 'experimenter', 'Type', 'char', 'Values', [], 'Label', 'Experimenter','Editable',0); 
opts_vars(13) = struct('Name', 'ExperimentType', 'Type', 'char', 'Values', [], 'Label', 'ExperimentType','Editable',0); 

%Define default values 

%Imaging Options
opts_vals.ExposureDuration = 20;  %Camera Exposure in ms
opts_vals.Framerate =1000/opts_vals.ExposureDuration; %Frame rate
opts_vals.RecordingDuration = 100; %Total duration of the recording in seconds

%Nidaq Aquisition Info
opts_vals.AnalogInRate = 1000; %samples/sec
opts_vals.AnalogOutRate = 1000; %samples/sec
opts_vals.DigitalOutRate = 1000; %samples/sec
opts_vals.DigitalInRate = 1000; %samples/sec

%Directory Info
opts_vals.RecDate = datestr(datetime('Now','Format','dd-MMM-uuuu HH:mm:ss'));
opts_vals.OptionsFilename = sprintf('%s-OptsFile.mat',mouse);
opts_vals.AquiredDataFilename = sprintf('%s-AquiredData.mat',mouse);
opts_vals.mouse = mouse; 
opts_vals.experimenter = experimenter;
opts_vals.ExperimentType = type;

end
