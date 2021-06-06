
import MultiCam as mc 

cam_numbers = mc.setCameraIDs(2)
video_names = mc.setFileIDs(2,"Z:\\Rodent Data\\Wide Field Microscopy\\Neuropixels_Widefield_CorticalDynamics\\Retinotopy\\Mouse331_06_05_2021\\")
mc.multi_cam_capture(cam_numbers,video_names, 60, [640,640], [480,480],"True",".avi",True, 97200, [1,0],"Z:\\Rodent Data\\Wide Field Microscopy\\Neuropixels_Widefield_CorticalDynamics\\Retinotopy\\Mouse331_06_05_2021\\")