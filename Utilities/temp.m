%To do: 
%1) decide 3 contrast levels and get the code that these are all generated
%in the same initialization function
%2) include that initialization function 
%deliver a stimulus every 6-10 seconds. so at a minimum of 3 baseline to subtract out, 1 during stim, 2 post stimulus
%3) write in a non trial-based way, with the photodiode capturing the
%data. 
%4) confirm that all aquisition is being recorded along with the
%photodiode on the Neuropixel computer
%5) confirm that neuropixel synrhonization signal (split) and camera signal
%(split) are being recorded on the behavioral computer. 
%6) also as a backup save the stimulus delivery times with the tic on the
%behavioral computer relative to the trigger delivery in case sync fails. 
%7) try with an example animal and confirm that everything is working
%nicely
%8) paint black on the to shut out light on animal brain
%9) option would be to use the HDMI splitter and directly record from
%there. 


[gratingOpts] = InitializeGratings(2);

showGrating(gratingOpts,anglechoice,1)