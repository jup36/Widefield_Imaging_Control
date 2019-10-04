
import MultiCam as mc 

cam_numbers = mc.setCameraIDs(2)
video_names = mc.setFileIDs(2,"Z:\\Rodent Data\\Wide Field Microscopy\\DataAquisition_GUI\\GUI_Version1\\Behavioral_MultiCam\\")
mc.camera_check(cam_numbers)