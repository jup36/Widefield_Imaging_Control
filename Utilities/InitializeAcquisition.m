function InitializeAcquisition(app)


    %Start Behavioral Monitoring 
    if app.ofCamsEditField.Value>0        
        filename = CreateVideoRecordingScript([app.rootdir filesep 'Behavioral_MultiCam' filesep],...
            app.SaveDirectoryEditField.Value,app.behav_cam_vals);
        cmd = sprintf('python "%s" && exit &',filename);
        system(cmd) 
        pause(app.behav_cam_options.flank_duration); %Start behavioral camera early 
    end       
end