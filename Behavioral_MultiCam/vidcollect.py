
import MultiCam as mc 

cam_numbers = mc.setCameraIDs(2)
video_names = mc.setFileIDs(2,"Z:\\Rodent Data\\Wide Field Microscopy\\ASD Models_Widefield\\Mouse336_07_30_2021\\")
mc.multi_cam_capture(cam_numbers,video_names, 60, [640,640], [480,480],"True",".avi",True, 235200, [1,1],"Z:\\Rodent Data\\Wide Field Microscopy\\ASD Models_Widefield\\Mouse336_07_30_2021\\")