
import MultiCam as mc 

cam_numbers = mc.setCameraIDs(2)
video_names = mc.setFileIDs(2,"C:\\Users\\buschmanlab\\Documents\\Widefield_Imaging_Control\\scratch\\")
mc.multi_cam_capture(cam_numbers,video_names, 60, [640,640], [480,480],"True",".avi",True, 283200, [1,1],"C:\\Users\\buschmanlab\\Documents\\Widefield_Imaging_Control\\scratch\\")