# mymod.py
"""Python module demonstrates passing MATLAB types to Python functions"""
def search(words):
    """Return list of words containing 'son'"""
    newlist = [w for w in words if 'son' in w]
    return newlist

def theend(numCam):
    """Set the CameraIDs"""
    camera_numbers = [int(i) for i in range(numCam)] 
    return camera_numbers

def setCameraIDs(numCam):
    """Append 'The End' to list of words"""
    words.append('The End')
    return words