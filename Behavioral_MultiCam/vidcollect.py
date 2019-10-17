
import MultiCam as mc 

cam_numbers = mc.setCameraIDs(2)
video_names = mc.setFileIDs(2,"C:\\Users\\macdo\\Documents\\GitHub\\Widefield_Imaging_Control\\Behavioral_MultiCam\\")
mc.multi_cam_capture(cam_numbers,video_names, 60, [320,640], [240,480],"True",".avi","True", 600,"C:\\Users\\macdo\\Documents\\GitHub\\Widefield_Imaging_Control\\Behavioral_MultiCam\\")