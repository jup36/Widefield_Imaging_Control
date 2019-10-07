
import MultiCam as mc 

cam_numbers = mc.setCameraIDs(2)
video_names = mc.setFileIDs(2,"C:\\Users\\mouse1\\Documents\\GitHub\\Widefield_Imaging_Control\\scratch\\")
mc.multi_cam_capture(cam_numbers,video_names, 60, 640, 480,"true",".avi","true", 1800)