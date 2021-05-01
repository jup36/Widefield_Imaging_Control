function [opts_vars, opts_vals] = BehavioralCameraConfiguration()

%Default Behavioral Camera Options

%Imaging Options
opts_vars(1) = struct('Name','record','Type','boolean','Values',[],'Label','Record','Editable',0); 
opts_vars(2) = struct('Name','duration_in_sec','Type','scalar','Values',[],'Label','Recording Duration (s)','Editable',0); 
opts_vars(3) = struct('Name','num_cam','Type','scalar','Values',[],'Label','#Cameras','Editable',1); 
opts_vars(4) = struct('Name','fps','Type','scalar','Values',[],'Label','Framerate','Editable',1); 
opts_vars(5) = struct('Name','w','Type','scalar','Values',[],'Label','width','Editable',0); 
opts_vars(6) = struct('Name','h','Type','scalar','Values',[],'Label','height','Editable',0); 
opts_vars(7) = struct('Name','show_feed','Type','boolean','Values',[],'Label','show_feed','Editable',1); 
opts_vars(8) = struct('Name','time_stamp','Type','boolean','Values',[],'Label','time_stamp','Editable',1); 
opts_vars(9) = struct('Name','filetype','Type','char','Values',['.avi'],'Label','FileType','Editable',1); 
opts_vars(10) = struct('Name','flank_duration','Type','scalar','Values',[],'Label','FlankDuration','Editable',1); 
opts_vars(11) = struct('Name','flip_image','Type','scalar','Values',[],'Label','flip_image','Editable',0); 

%Define default values 
opts_vals.record = 1; %1=record video, 0=check cameras
opts_vals.num_cam = 2; %Number of Cameras
opts_vals.fps = 60; %frame rate of behvaioral acq cameras
opts_vals.duration_in_sec = 10; %duration of the recording in second
opts_vals.w =[640,640];
opts_vals.h =[480,480];
opts_vals.show_feed = 1; %Show feed from camera 1 (only works for camera 1)
opts_vals.time_stamp = 1'; %Add timestamps to the recording file
opts_vals.filetype = '.avi';
opts_vals.flank_duration = 10; %duration in seconds that behavioral cameras will start and end before and after the imaging
opts_vals.flip_image = [1,0]; %1 = rotate camera view 180, 0 = no rotation

end
