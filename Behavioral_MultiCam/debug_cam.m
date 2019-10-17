%% Start behavioral aquisition
%Define default values 
opts_vals.record = 1; %1=record video, 0=check cameras
opts_vals.num_cam = 2; %Number of Cameras
opts_vals.fps = 60; %frame rate of behvaioral acq cameras
opts_vals.duration_in_sec = 10; %duration of the recording in second
opts_vals.w = [320,640];
opts_vals.h = [240,480];
opts_vals.show_feed = 1; %Show feed from camera 1 
opts_vals.time_stamp = 1'; %Add timestamps to the recording file
opts_vals.filetype = '.avi';
opts_vals.flank_duration = 10; %duration in seconds that behavioral cameras will start and end before and after the imaging
%%
filename =  CreateVideoRecordingScript([pwd filesep],...
    [pwd filesep],opts_vals);
%%
cmd = sprintf('python "%s" %% Exit &',filename);
system(cmd)
