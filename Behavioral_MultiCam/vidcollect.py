
import MultiCam as mc 

cam_numbers = mc.setCameraIDs(2)
video_names = mc.setFileIDs(2,"Z:\\Rodent Data\\Wide Field Microscopy\\ControlExperiments_WidefieldData\\Retinotropy\\")
mc.multi_cam_capture(cam_numbers,video_names, 60, [640,640], [480,480],"True",".avi","True", 121200, [1,0],"Z:\\Rodent Data\\Wide Field Microscopy\\ControlExperiments_WidefieldData\\Retinotropy\\")