function [opts_vars, opts_vals] = auditory_conditioning_operant_reversal_config(mouse,experimenter,type)

% All routines for Widefield Imaging Aquisition must follow this format

%Define types of options for the routine 
% @Values: specific list of usable values
% @Editable: If not edible, will not show up in edit configuration dialog

%General Options
opts_vars(1) = struct('Name','routine_name','Type','char','Values',[],'Label','AssociatedRoutine','Editable',1); 

%Imaging Options
opts_vars(2) = struct('Name','exposure_duration','Type','scalar','Values',[],'Label','Exposure (ms)','Editable',1); 
opts_vars(3) = struct('Name','framerate','Type','scalar','Values',[],'Label','Framerate','Editable',0); 
opts_vars(4) = struct('Name','recording_duration','Type','scalar','Values',[],'Label','Duration (s)','Editable',1); 
opts_vars(5) = struct('Name', 'rec_date', 'Type', 'char', 'Values', [], 'Label', 'RecDate','Editable',0); 
opts_vars(6) = struct('Name', 'mouse', 'Type', 'char', 'Values', [], 'Label', 'mouse','Editable',0); 
opts_vars(7) = struct('Name', 'experimenter', 'Type', 'char', 'Values', [], 'Label', 'Experimenter','Editable',0); 
opts_vars(8) = struct('Name', 'experiment_type', 'Type', 'char', 'Values', [], 'Label', 'ExperimentType','Editable',0); 
%sequence options
opts_vars(9) = struct('Name','number_sequence','Type','scalar','Values',[],'Label','Number of Sequences','Editable',1);
opts_vars(10) = struct('Name','NTrials_per_sequence','Type','scalar','Values',[],'Label','NTrials per Sequence','Editable',0);

%%Define default values 
%General Options
opts_vals.routine_name='auditory_conditioning_operant_reversal';

%Imaging Options
opts_vals.exposure_duration = 25;  %Camera Exposure in ms (the actual camera exposure time is 12.5 ms). 
opts_vals.framerate =1000/opts_vals.exposure_duration; %Frame rate
opts_vals.number_sequence = 40; %this is the number of sequence of 10 reward
opts_vals.NTrials_per_sequence = 10; 
opts_vals.recording_duration=95*opts_vals.number_sequence; %Total duration of the recording in seconds.

%Directory Info
opts_vals.rec_date = datestr(datetime('Now','Format','dd-MMM-uuuu HH:mm:ss'));
opts_vals.mouse = mouse; 
opts_vals.experimenter = experimenter;
opts_vals.experiment_type = type;

%Input/Output Mapping
%opts_vals.trigger_ready_chan = 1;

end
