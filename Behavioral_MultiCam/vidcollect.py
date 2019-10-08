
import MultiCam as mc 

cam_numbers = mc.setCameraIDs(2)
video_names = mc.setFileIDs(2,"Z:\\Users\\Norbert\\Sequences\\BimodalSequences\\TimingTests\\Rec_Strobe_Camera_10-8-2019\\")
mc.multi_cam_capture(cam_numbers,video_names, 50, 640, 480,"true",".avi","true", 5000)