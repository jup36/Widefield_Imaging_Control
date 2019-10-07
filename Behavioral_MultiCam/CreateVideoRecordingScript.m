function [filename, opts] = CreateVideoRecordingScript(rootdir,savedir,opts,varargin)
% Camden MacDowell 2019
% Creates a python file that captures simultaneos usb camera input. 
% Python recording script and videos saved to rootdir
% Optionally (opts.Record) can just be used to test videos
% Requires python dependencies to be on system path: 
% MultiCam.py, capture.py, os, time, numpy, cv2

if nargin <3
    [~, opts] = BehavioralCameraConfiguration();
end

%Process optional inputs
if mod(length(varargin), 2) ~= 0, error('Must pass key/value pairs for options.'); end
for i = 1:2:length(varargin)
    try
        opts.(varargin{i}) = varargin{i+1};
    catch
        error('Couldn''t set option ''%s''.', varargin{2*i-1});
    end
end

% Contingencies
if opts.h ~= 480 || opts.w ~=640
    error('VIDEO SIZE ERROR: Only 640x480 videos current supported. Change configurations');
end

%% Body

%Convert logicals to strings for python
x = {"false","true"};

filename = [rootdir 'vidcollect.py']; 
fid = fopen(filename, 'wt');

fprintf(fid, '\nimport MultiCam as mc \n');
fprintf(fid, '\ncam_numbers = mc.setCameraIDs(%d)',opts.num_cam);
fprintf(fid, '\nvideo_names = mc.setFileIDs(%d,"%s")',opts.num_cam,formatPathToPython(savedir));
if opts.record
        fprintf(fid, ['\nmc.multi_cam_capture(cam_numbers,',...
        'video_names,',...
        sprintf(' %d,',opts.fps),...
        sprintf(' %d,',opts.w),...
        sprintf(' %d,',opts.h),...
        sprintf('"%s",',x{opts.time_stamp+1}),...
        sprintf('"%s",',opts.filetype),...
        sprintf('"%s",',x{opts.show_feed+1}),...
        sprintf(' %d',opts.duration_in_sec*opts.fps),...
        ')']); 
else
    fprintf(fid, '\nmc.camera_check(cam_numbers)');
end
fclose(fid);

end



