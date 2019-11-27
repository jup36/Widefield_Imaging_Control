
import MultiCam as mc 

cam_numbers = mc.setCameraIDs(2)
video_names = mc.setFileIDs(2,"Z:\\Rodent Data\\Wide Field Microscopy\\ParietalCortex_Ephys_Widefield\\Mouse501_11_27_2019\\")
mc.multi_cam_capture(cam_numbers,video_names, 60, [320,640], [240,480],"True",".avi","True", 241200,"Z:\\Rodent Data\\Wide Field Microscopy\\ParietalCortex_Ephys_Widefield\\Mouse501_11_27_2019\\")