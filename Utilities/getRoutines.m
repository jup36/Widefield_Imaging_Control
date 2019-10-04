function routines = getRoutines(directory)

routines = dir([directory filesep '*.m']);
routines = {routines(:).name};

%remove the trailsing .m
for i = 1:numel(routines)
    routines{i}(end-1:end)='';
end

end


