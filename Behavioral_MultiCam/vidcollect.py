
import MultiCam as mc 

cam_numbers = mc.setCameraIDs(2)
video_names = mc.setFileIDs(2,"E:\\SinaRecs\\Mouse1625\\ACHVisRew_continous\\")
mc.multi_cam_capture(cam_numbers,video_names, 60, [640,640], [480,480],"True",".avi",True, 37200, [1,1],"E:\\SinaRecs\\Mouse1625\\ACHVisRew_continous\\")