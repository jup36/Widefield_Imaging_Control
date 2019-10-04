




filename = CreateVideoRecordingScript('C:\Users\mouse1\Documents\Python_Repository\MultiCam_Aquisition\','Record',1);
cmd = sprintf('python "%s" && exit &',filename);
system(cmd)


