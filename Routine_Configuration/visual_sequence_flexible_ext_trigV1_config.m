function [opts_vars, opts_vals] = visual_sequence_flexible_ext_trigV1_config(mouse,experimenter,type)

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

%trial options
opts_vars(20) = struct('Name','number_trials','Type','scalar','Values',[],'Label','Number of Trials','Editable',1); 

% Flexible sequence (DynamicDialog: multiline OK, or one line use ; between records)
opts_vars(21) = struct('Name','flex_stim_definition','Type','char','Values',[],'Label','Flex stims (name,angle,ctr)','Editable',1);
opts_vars(22) = struct('Name','flex_sequence_definition','Type','char','Values',[],'Label','Flex seqs (p,n1,n2,...)','Editable',1);
opts_vars(23) = struct('Name','flex_stim_duration','Type','scalar','Values',[],'Label','Grating on (s)','Editable',1);
opts_vars(24) = struct('Name','flex_isi','Type','scalar','Values',[],'Label','ISI (s)','Editable',1);
opts_vars(25) = struct('Name','flex_post_trial','Type','scalar','Values',[],'Label','Post trial (s)','Editable',1);

%%Define default values 
%General Options
opts_vals.routine_name='visual_sequence_flexible_ext_trigV1';

%Imaging Options
opts_vals.exposure_duration = 33.33;  %Camera Exposure in ms
opts_vals.framerate =1000/opts_vals.exposure_duration; %Frame rate
%opts_vals.recording_duration = 4700; %Total duration of the recording in seconds. put 4000 for 500 trials

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

%Input/Output Mapping
opts_vals.expose_out_chan = 0;
opts_vals.frame_readout_chan = 3; 
opts_vals.trigger_ready_chan = 1;
opts_vals.photodiode_chan = 2;
opts_vals.trigger_out_chan = 1;

%General Options
opts_vals.number_trials = 1500;
opts_vals.recording_duration = 4700; %Total duration of the recording in seconds. put 4000 for 500 trials


% Flexible text: newlines OK in Edit Routine dialog; single-line GUIs may use ; between rows.
% In sequences: , , or ,, = blank (gray); $ = random stim with replacement (each $ a new draw at show time).
opts_vals.flex_stim_definition = sprintf([ ...
    'A,20,1\n' ...
    'B,80,1\n' ...
    'C,40,1\n' ...
    'D,60,1\n' ...
    'X,160,1\n' ...
    'Y,100,1\n' ...
    'Z,120,1\n' ...
    'W,140,1' ]);
opts_vals.flex_sequence_definition = sprintf([ ...
    '0.35,A,B,C,D\n' ...
    '0.35,X,Y,Z,D\n' ...
    '0.07,A,B,Z,D\n' ...
    '0.07,X,Y,C,D\n' ...
    '0.06,A, ,C,D\n' ...
    '0.06,W, ,C,D\n' ...
    '0.04,$,$,$,$' ]);
opts_vals.flex_stim_duration = 0.25;
opts_vals.flex_isi = 0.05;
opts_vals.flex_post_trial = 0;

end
