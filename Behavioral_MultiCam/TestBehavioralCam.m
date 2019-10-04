function TestBehavioralCam(app)
        filename = CreateVideoRecordingScript([app.rootdir filesep 'Behavioral_MultiCam' filesep],app.rootdir,...
            'record',0,'num_cam',app.ofCamsEditField.Value,'fps',app.FPSEditField.Value);
        cmd = sprintf('python "%s" && exit &',filename);
        system(cmd) 
end