
import MultiCam as mc 

cam_numbers = mc.setCameraIDs(2)
video_names = mc.setFileIDs(2,"Z:\\Rodent Data\\Behavioral_dynamics_cj\\test_auditory_cond\\test4_040523\\")
mc.multi_cam_capture(cam_numbers,video_names, 60, [640,640], [480,480],"True",".avi",True, 4080, [1,1],"Z:\\Rodent Data\\Behavioral_dynamics_cj\\test_auditory_cond\\test4_040523\\")