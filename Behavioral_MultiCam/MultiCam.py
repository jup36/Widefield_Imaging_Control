# Camden MacDowell 2019
# Core aquisition functions from https://optogeneticsandneuralengineeringcore.gitlab.io
#
# A simple script for multi-camera recording. 
# 
# Works with most webcams and PS3 eye cam (with driver: https://github.com/jkevin/PS3EyeDirectShow/releases)
# On windows only one PS3 Cam will work at once.  

# Import libraries
import os
import numpy as np
import cv2
import time
from capture import VideoCaptureTreading

## Load and parse configuration file saved off from matlab 

###### DEFINE FUNCTION FROM THE 
def setCameraIDs(numCam=2):
    """Set the CameraIDs"""
    camera_numbers = [int(i) for i in range(numCam)] 
    return camera_numbers

def setFileIDs(numCam=2,savedir=''):
    """Set the FileIDs"""
    names = [f'Cam_{i}' for i in range(numCam)] 
    video_names = []
    for name in names:
        video_names += [savedir + name]   
    return video_names

# Declare Multi Camera Capture Function
def multi_cam_capture(
    cam_numbers = None,
    video_names = None,
    fps = 60.0,
    width = [320, 640, 640],
    height = [240, 480, 480],
    time_stamp = True,
    filetype = '.avi',
    show_feed = True,
    frame_limit = 50,
    flip_image = [0,0],
    savedir=''):
    """Capture video from multiple cameras simultaneously"""

    print("RECORDING for %d frames at %d fps = ~%d seconds. Press Q to quit early" %(frame_limit,fps,frame_limit/fps))
    # Set up cameras and video files
    if cam_numbers == None:
        cam_numbers = list(range(len(video_names)))
        
    # Set up filenames
    timestr = ''
    if time_stamp:
        timestr += '_' + time.strftime("%Y%m%d-%H%M%S")
    video_filenames = []
    for name in video_names:
        video_filenames += [name + timestr + filetype]   
    
    # Set up camera feeds and video files
    cameras = []
    videos = []
    fourcc = cv2.VideoWriter_fourcc(*'XVID')
    for index, filename in enumerate(video_filenames):
        cameras += [VideoCaptureTreading(cam_numbers[index],width[index],height[index])]
        videos += [cv2.VideoWriter(filename, fourcc, fps, (width[index],height[index]))]

    for camera in cameras:
        camera.start()
        
    #Set up current timestamp data array
    timestamps_now = np.zeros((1,len(cam_numbers)))
    
    # Keep grabbing video frames until keypress
    while(cameras[0].started):
        # Fetch data from cameras
        ret, frames = [], []
        for cam_num, camera in enumerate(cameras):
            captured, frame = camera.read()
            if flip_image[cam_num]==1:
                frame = cv2.flip(frame,0)
            ret.append(captured)
            frames.append(frame)
            timestamps_now[0,cam_num] = time.time()            

        # Write to file if data received from all cameras
        if all(ret):
            for vid_num, video in enumerate(videos):
                video.write(frames[vid_num])  # write the flipped frame
            try:
                timestamps_all = np.append(timestamps_all, 
                                           timestamps_now, 
                                           axis=0)
            except:
                timestamps_all = np.copy(timestamps_now)
                print("Timestamps initialized")
            if show_feed: 
                cv2.imshow('Video Feed',frames[1])
            num_frames = timestamps_all.shape[0]
            if num_frames>=frame_limit:
                break
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break  # exit if Q-key pressed
        else:
            print("\nERROR!\nCould not connect to cameras!\nEnding Recording")
            break  # exit frames not retrieved  
        

    # Release everything if job is finished   
    for camera in cameras:
        camera.stop()
    #for camera in cameras:
    #    camera.release()
    for video in videos:
        video.release()
    cv2.destroyAllWindows()
    
    #Clean up timestamp data
    num_frames = timestamps_all.shape[0]
    print("Captured " + str(num_frames) + " frames")
    time_init = np.copy(timestamps_all[0,0])
    for index in range(num_frames):
        timestamps_all[index,:] = np.copy(timestamps_all[index,:] - time_init)    
    np.savetxt(savedir + "timestamps" +  timestr + ".csv", timestamps_all, delimiter=",")
    
    
    
def camera_check(
    cam_numbers=[0],
    flip_image = [0,0]):
    """Display video feeds"""
    
    # Set up camera feeds and video files
    cameras = []
    for cam_number in cam_numbers:
        cameras += [VideoCaptureTreading(cam_number)]
    for camera in cameras:
        camera.start()
        
    
    # Keep grabbing video frames until keypress or until reach frame limit
    print("Displaying live video feed. Press Q to quit")
    while(cameras[0].started):
        # Fetch data from cameras
        ret, frames = [], []
        for cam_num, camera in enumerate(cameras):
            captured, frame = camera.read()
            if flip_image[cam_num]==1:
                frame = cv2.flip(frame,0)
            ret.append(captured)
            frames.append(frame)
        
        # Display cameras
        if all(ret):
            for frame_num, cam_num in enumerate(cam_numbers):
                cam_label = "Camera" + str(cam_num)
                cv2.imshow(cam_label,frames[frame_num])
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break  # exit if Q-key pressed
        else:
            print("\nERROR!\nCould not connect to cameras!\nEnding Recording")
            break  # exit frames not retrieved
        
    # Release everything if job is finished   
    for camera in cameras:
        camera.stop()

    cv2.destroyAllWindows()
    print("Video feed ended")
    
##############################################################################    
    
if __name__ == "__main__":
   numCam = 2; 
   camera_check(cam_numbers = setCameraIDs(numCam))
#   multi_cam_capture(cam_numbers = setCameraIDs(numCam), 
#                     video_names = setFileIDs(numCam),
#                     fps = 60.0,
#                     width = 640,
#                     height = 480,
#                     time_stamp = True,
#                     show_feed = True);
#                     
#    
    
    
   