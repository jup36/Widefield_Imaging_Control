function visual_sequence_flexible_ext_trigV1(app)
% Retinotopy-style imaging with GUI-defined stimulus alphabet and sequences.
% Configure in the routine dialog:
%   flex_stim_definition   — one stimulus per line: name,angle_deg,contrast
%   flex_sequence_definition — one sequence type per line: prob,name1,name2,...
%       Blank = gray ( , or ,,). $ = random stimulus with replacement (e.g. 0.5,$,$,$,$).
%   flex_stim_duration, flex_isi, flex_post_trial — timing in seconds
% Lines starting with # are comments; use newlines or ; between lines in the text fields.

%check if save directory exists
if ~exist(app.SaveDirectoryEditField.Value)
    mkdir(app.SaveDirectoryEditField.Value)
else
    %confirm no log file already in the directory... to be extra safe,
    %adding timestamp to all filenames
    if exist([app.SaveDirectoryEditField.Value '%s_acquisitionlog.m'])~=0
        uialert(app.UIFigure,['Save dir already contains log file. Aquisition cancelled.\n',...
            'Select new save directory and try again'],'Overwrite Notice')     
        return
    end
end

[seqopts, stim_type_cell, parseErr] = ParseFlexibleVisualSequence(app.cur_routine_vals);
if ~isempty(parseErr)
    uialert(app.UIFigure, parseErr, 'Flexible sequence config');
    return
end

% Face camera (pySpin) setup when using cameras - continuous_camera_recording style
nidq_faceCam = [];
videoSaveDir = [];
videoSaveDir = uigetdir([], 'Select folder where face camera videos will be saved');
if videoSaveDir == 0
    return
end
% Create nidq_faceCam for face camera pulses (PFI13 / ctr1, 200 Hz)
nidq_faceCam = daq("ni");
nidq_faceCam.Rate = 3*1e5;
ch_faceCam = addoutput(nidq_faceCam, "Dev1", 'ctr1', "PulseGeneration");
ch_faceCam.Frequency  = 200;
ch_faceCam.DutyCycle  = 0.5;
stimopts.tail_camera_frame_padding = 10;
stimopts.total_duration_sequence = app.behav_cam_vals.duration_in_sec + app.behav_cam_vals.flank_duration + 10;
behav_camera_pulse_dur = ceil(stimopts.total_duration_sequence) + 10;
Cmd_to_pulse_delay = 5;

stimDur = seqopts.flex_stim_duration;
isiDur = seqopts.flex_isi;
postTrial = seqopts.flex_post_trial;

%% Initialize inputs/outputs and log file
%Analog Inputs
a = daq.createSession('ni');
% a.addAnalogInputChannel('Dev1',[0,1,6,7,20,21],'Voltage')
% a.Rate = app.cur_routine_vals.analog_in_rate;
channels = [app.cur_routine_vals.expose_out_chan,...
    app.cur_routine_vals.frame_readout_chan,...
    app.cur_routine_vals.photodiode_chan,...
    app.cur_routine_vals.trigger_ready_chan];
    
for chan = 1:numel(channels)
    c = channels(chan);
    ch = addAnalogInputChannel(a, 'Dev1', c,'Voltage');
    if c ~= app.cur_routine_vals.photodiode_chan
        ch.TerminalConfig = 'SingleEnded';
    end
end
a.Rate = app.cur_routine_vals.analog_in_rate;

%Analog Output 
s = daq.createSession('ni');
s.Rate = app.cur_routine_vals.analog_out_rate;
s.addAnalogOutputChannel('Dev1',sprintf('ao%d',app.cur_routine_vals.trigger_out_chan),'Voltage')

%Create and open the log file
log_fn = [app.SaveDirectoryEditField.Value filesep sprintf('%s_acquisitionlog.m',datestr(now,'mm-dd-yyyy-HH-MM'))];
logfile = fopen(log_fn,'w');

% Stimuli and trial list from GUI (seqopts, stim_type_cell from ParseFlexibleVisualSequence)
[opts] = InitializeStaticGrating(seqopts.angle,seqopts.contrast);
KbName('UnifyKeyNames');
RestrictKeysForKbCheck(KbName('ESCAPE'));
escKeyCleanup = onCleanup(@() RestrictKeysForKbCheck([]));

%Start listener
lh = addlistener(a,'DataAvailable', @(src,event)LogAquiredData(src,event,logfile)); % Create event listener bound to event source
a.IsContinuous = true;
a.startBackground; %Start aquisition

%get random ITI. For less jitter relative to exposure - choose interval. 
%divide by two so that it's an interval of a single wavelength
ITI = [1*round(app.cur_routine_vals.framerate/2),2*round(app.cur_routine_vals.framerate/2)];

try %recording loop catch to close log file and delete listener
    % Trigger CMOS camera pulses (continuous) if enabled
     start(app.nidq_cmos, "continuous");

    %% Start behavioral aquisition
    filename = CreateVideoRecordingScript([app.rootdir filesep 'Behavioral_MultiCam' filesep],...
        [app.SaveDirectoryEditField.Value filesep],app.behav_cam_vals,'duration_in_sec',...
        (app.behav_cam_vals.duration_in_sec+app.behav_cam_vals.flank_duration+10));
    cmd = sprintf('python "%s" && exit &',filename);
    system(cmd)
    % Launch face camera (pySpin) continuous capture - continuous_camera_recording style
    batchFilePath = "C:\Users\buschmanlab\Documents\pySpinCapture\run_faceCam_capture_continous.bat";
    mouse_id = char(app.cur_routine_vals.mouse);
    cmd_face = sprintf('"%s" %d %s %d "%s" && exit &', ...
        batchFilePath, behav_camera_pulse_dur, mouse_id, 1, videoSaveDir);
    system(cmd_face);
    WaitSecs(Cmd_to_pulse_delay);
    start(nidq_faceCam, "Continuous");
    WaitSecs(0); %Start behavioral camera early since takes a few secs to build up
    fprintf('\nBegining Recording');

    % test
    %% Recording
    userAborted = false;
    %loop through trials (ESC during stimulus or ITI to stop)
    nStim = numel(opts.gratingtex);
    for i = 1:numel(stim_type_cell)
        % Resolve $ (-1) to concrete stimulus indices for this trial (saved in stimInfo.mat)
        trialSeq = ResolveRandomStimulusSlots(stim_type_cell{i}, nStim);
        stim_type_cell{i} = trialSeq;
        seqopts.stim_type_token_labels{i} = SequenceIdxToLabelStr(trialSeq, seqopts.seq_names);

        itiSec = randi(ITI,1)*1/round(app.cur_routine_vals.framerate/2);
        trigSec = 5/round(app.cur_routine_vals.framerate);
        nSlots = numel(trialSeq);
        gratBlockSec = nSlots*stimDur + max(0, nSlots-1)*isiDur;
        trialLenSec = trigSec + gratBlockSec + postTrial + itiSec;
        trialTypeStr = seqopts.stim_type_token_labels{i};
        fprintf('\nTrial %d/%d: type=%s, planned_length_s=%.4f\n', i, numel(stim_type_cell), trialTypeStr, trialLenSec);

        %Trigger camera start with a 10ms pulse
        outputSingleScan(s,4); %deliver the trigger stimuli (4V)
        if WaitSecsOrEsc(trigSec)
            userAborted = true; break
        end
        outputSingleScan(s,0); %deliver the trigger stimuli
        WaitSecsOrEsc(0.02); %wait 20ms so we can see all of the pulses
        %deliver stimulus sequence (variable length)
        if showGrating(opts,trialSeq,stimDur,isiDur,s)
            userAborted = true; break
        end

        if WaitSecsOrEsc(postTrial)
            userAborted = true; break
        end

        %wait a random interval based on exposure length
        if WaitSecsOrEsc(itiSec)
            userAborted = true; break
        end

        fprintf('\n\tDone with trial %d',i);
    end

    if userAborted
        fprintf('\nRecording stopped by user (ESC).\n');
    end
    fprintf('\nDone Recording... Filling buffer and wrapping up...');
    %Post rec pause to make sure everything aquired.
    WaitSecs(stimopts.tail_camera_frame_padding);
    stop(nidq_faceCam);
    WaitSecs(app.behav_cam_vals.flank_duration);


    pause(10); %this MUST be pause. WaitSecs does not trigger buffer fill
    a.stop; %Stop aquiring
    fprintf('\nSaving Log ... Please wait')
    fclose(logfile); %close this log file.
    delete(lh); %Delete the listener for this log file
    fprintf('\nSuccesssfully completed recording.')
    recordingparameters = {app.cur_routine_vals,app.behav_cam_vals};
    save([app.SaveDirectoryEditField.Value,filesep sprintf('%s_stimInfo.mat',datestr(now,'mm-dd-yyyy-HH-MM'))],...
        'stim_type_cell','seqopts');
    save([app.SaveDirectoryEditField.Value,filesep sprintf('%s_recordingparameters.mat',datestr(now,'mm-dd-yyyy-HH-MM'))],'recordingparameters');
    fprintf('Successsfully completed recording. Wrapping up...')
    Screen('closeAll')

    % Stop CMOS camera pulses (continuous) if enabled
     stop(app.nidq_cmos);
 
catch %make sure you close the log file and delete the listened if issue
    fclose(logfile);
    delete(lh);
    if ~isempty(nidq_faceCam)
        try
            stop(nidq_faceCam);
        catch
        end
    end
end


