
import MultiCam as mc 

cam_numbers = mc.setCameraIDs(2)
video_names = mc.setFileIDs(2,"Z:\\Rodent Data\\ImagingEphys_SinaT\\Pilot Tests\\Sequence\\Mouse1625\\Sequence Exp Series Reversal\\06222026\\")
mc.multi_cam_capture(cam_numbers,video_names, 60, [640,640], [480,480],"True",".avi",True, 283200, [1,1],"Z:\\Rodent Data\\ImagingEphys_SinaT\\Pilot Tests\\Sequence\\Mouse1625\\Sequence Exp Series Reversal\\06222026\\")