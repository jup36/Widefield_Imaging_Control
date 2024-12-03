function [opts_vars, opts_vals] = resting_state_with_behv_cameras_Nmin_config(mouse,experimenter,type)

% All routines for Widefield Imaging Aquisition must follow this format

%Define types of options for the routine 
% @Values: specific list of usable values
% @Editable: If not edible, will not show up in edit configuration dialog

%General Options
opts_vars(1) = struct('Name','routine_name','Type','char','Values',[],'Label','AssociatedRoutine','Editable',1); 

%Imaging Options
opts_vars(2) = struct('Name','exposure_duration','Type','scalar','Values',[],'Label','Exposure (ms)','Editable',1); 
opts_vars(3) = struct('Name','framerate','Type','scalar','Values',[],'Label','Framerate','Editable',0); 
opts_vars(4) = struct('Name','number_sequence','Type','scalar','Values',[],'Label','Number of Sequences','Editable',1); 
opts_vars(5) = struct('Name','sequence_duration','Type','scalar','Values',[],'Label','Sequence duration (s)','Editable',1); 
opts_vars(6) = struct('Name','recording_duration','Type','scalar','Values',[],'Label','Recording duration (s)','Editable',1); 
opts_vars(7) = struct('Name', 'rec_date', 'Type', 'char', 'Values', [], 'Label', 'RecDate','Editable',0); 
opts_vars(8) = struct('Name', 'mouse', 'Type', 'char', 'Values', [], 'Label', 'mouse','Editable',0); 
opts_vars(9) = struct('Name', 'experimenter', 'Type', 'char', 'Values', [], 'Label', 'Experimenter','Editable',0); 
opts_vars(10) = struct('Name', 'experiment_type', 'Type', 'char', 'Values', [], 'Label', 'ExperimentType','Editable',0); 
%opts_vars(6) = struct('Name', 'options_filename', 'Type', 'char', 'Values', [], 'Label', 'OptionsFilename','Editable',0); 
%opts_vars(7) = struct('Name', 'acquired_data_filename', 'Type', 'char', 'Values', [], 'Label', 'DataFilename','Editable',0); 


%Input/Output Mapping Info
%opts_vars(11) = struct('Name','trigger_ready_chan','Type','scalar','Values',[0,1,2,3,4,5],'Label','Trigger Ready Chan','Editable',1); 

%%Define default values 
%General Options
opts_vals.routine_name='resting_state_with_behv_cameras_Nmin';

%Imaging Options (DynamicDialog.m handles assignment of values below to the matching opts_vars above when this config code is run)
opts_vals.exposure_duration = 25;  %Camera Exposure in ms (the actual camera exposure time is 12.5 ms). 
opts_vals.framerate =1000/opts_vals.exposure_duration; %Frame rate
opts_vals.number_sequence = 1; % Will run one 5-min long sequence once 
opts_vals.sequence_duration = 300; % 300s (5m) 
opts_vals.recording_duration=opts_vals.number_sequence*opts_vals.sequence_duration; %Total duration of the recording in seconds.

%Directory Info
opts_vals.rec_date = datestr(datetime('Now','Format','dd-MMM-uuuu HH:mm:ss'));
opts_vals.mouse = mouse; 
opts_vals.experimenter = experimenter;
opts_vals.experiment_type = type;
%opts_vals.options_filename = sprintf('%s-OptsFile.mat',mouse);
%opts_vals.acquired_data_filename = sprintf('%s-AquiredData.mat',mouse);

%Input/Output Mapping
%opts_vals.trigger_ready_chan = 1;

end
