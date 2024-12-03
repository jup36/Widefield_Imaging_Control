function addPythonPath
%pyExec = 'C:\Users\chrli\anaconda3\';
pyRoot = 'C:\Users\mouse1\anaconda3\envs\behvid';  %fileparts(pyExec);
p = getenv('PATH');
p = strsplit(p, ';');
addToPath = {
   pyRoot
   fullfile(pyRoot, 'Library', 'mingw-w64', 'bin')
   fullfile(pyRoot, 'Library', 'usr', 'bin')
   fullfile(pyRoot, 'Library', 'bin')
   fullfile(pyRoot, 'Scripts')
   fullfile(pyRoot, 'bin')
};
p = [addToPath(:); p(:)];
p = unique(p, 'stable');
p = strjoin(p, ';');
setenv('PATH', p);

        cmd = sprintf('python "%s" && exit &',"C:\Users\mouse1\Documents\GitHub\pySpinCapture\cameraCapturePulse.py test012 1");
        system(cmd) 

end