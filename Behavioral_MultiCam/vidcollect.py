
import MultiCam as mc 

cam_numbers = mc.setCameraIDs(3)
video_names = mc.setFileIDs(3,"C:\\Users\\macdo\\Documents\\GitHub\\Widefield_Imaging_Control\\Behavioral_MultiCam\\")
mc.camera_check(cam_numbers)