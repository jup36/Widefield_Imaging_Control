function filename = CreateVideoRecordingScript(savedir,varargin)
% Camden MacDowell 2019
% Creates a python file that captures simultaneos camera webcam input using
% the MultiCam.py module. Python recording script and videos saved to
% savedir
% Optionally (opts.Record) can just be used to test videos
% Requires python dependencies to be on path: 
% MultiCam.py, capture.py, os, time, numpy, cv2


%Set optional inputs (easily expanded to add all modifiable features of
%python script). 

opts.Record = 1; %1=record video, 0=check cameras
opts.NumCam = 2; %Number of Cameras
opts.fps = 60; %frame rate of behvaioral acq cameras
opts.DurationInSec = 10; %duration of the recording in second
opts.w = 640; 
opts.h = 480; 
opts.show_feed = 'True'; %Show feed from camera 1 
opts.time_stamp = 'True'; %Add timestamps to the recording file
opts.filetype = '.avi';


%Process optional inputs
if mod(length(varargin), 2) ~= 0, error('Must pass key/value pairs for options.'); end
for i = 1:2:length(varargin)
    try
        opts.(varargin{i}) = varargin{i+1};
    catch
        error('Couldn''t set option ''%s''.', varargin{2*i-1});
    end
end

%% Contingencies
if opts.h ~= 480 || opts.w ~=640
    error('VIDEO SIZE ERROR: Only 640x480 videos current supported');
end

%% Body
filename = [savedir 'vidcollect.py']; 
fid = fopen(filename, 'wt');

fprintf(fid, '\nimport MultiCam as mc \n');
fprintf(fid, '\ncam_numbers = mc.setCameraIDs(%d)',opts.NumCam);
fprintf(fid, '\nvideo_names = mc.setFileIDs(%d,"%s")',opts.NumCam,formatPathToPython(savedir));
if opts.Record
        fprintf(fid, ['\nmc.multi_cam_capture(cam_numbers,',...
        'video_names,',...
        sprintf(' %d,',opts.fps),...
        sprintf(' %d,',opts.w),...
        sprintf(' %d,',opts.h),...
        sprintf(' %s,',opts.time_stamp),...
        sprintf(' "%s",',opts.filetype),...
        sprintf(' %s,',opts.show_feed),...
        sprintf(' %d',opts.DurationInSec*opts.fps),...
        ')']); 
else
    fprintf(fid, '\nmc.camera_check(cam_numbers)');
end
fclose(fid);

end



