
import MultiCam as mc 

cam_numbers = mc.setCameraIDs(2)
video_names = mc.setFileIDs(2,"C:\\Users\\mouse1\\Documents\\GitHub\\Widefield_Imaging_Control")
mc.camera_check(cam_numbers)