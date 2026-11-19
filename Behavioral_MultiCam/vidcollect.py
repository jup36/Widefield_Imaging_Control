
import MultiCam as mc 

cam_numbers = mc.setCameraIDs(2)
video_names = mc.setFileIDs(2,"E:\\SinaRecs\\Mouse1625\\BGLR Psilocybin Sequence PS2\\")
mc.multi_cam_capture(cam_numbers,video_names, 60, [640,640], [480,480],"True",".avi",True, 361200, [1,1],"E:\\SinaRecs\\Mouse1625\\BGLR Psilocybin Sequence PS2\\")