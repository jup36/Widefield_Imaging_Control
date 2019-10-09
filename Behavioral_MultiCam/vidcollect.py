
import MultiCam as mc 

cam_numbers = mc.setCameraIDs(2)
video_names = mc.setFileIDs(2,"Z:\\Users\\Norbert\\Resting_State\\Mouse422-10-8-2019\\")
mc.multi_cam_capture(cam_numbers,video_names, 50, 640, 480,"true",".avi","true", 66000)