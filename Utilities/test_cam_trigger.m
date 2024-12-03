
subject='test3';
pulse_dur = 10;

nidq = daq("ni");
nidq.Rate = 3*1e5; % 300KHz
ch_pulse = addoutput(nidq, "Dev27", 'ctr0', "PulseGeneration");
ch_pulse.Frequency = 500; % 500 Hz
ch_pulse.DutyCycle = 0.25;

recording_date=string(datetime('now','Format','yyyy_MM_dd'));

nidq_dg = daq("ni"); 
nidq_dg.Rate = 3*1e5; % 300K Hz
nidq_out_list = ["audio", "airpuff", "water","trigger"]; 
addoutput(nidq_dg, "Dev27", "ao0", "Voltage"); % audio
addoutput(nidq_dg, "Dev27", "Port0/Line8", "Digital"); % airpuff
addoutput(nidq_dg, "Dev27", "Port0/Line9", "Digital"); % water
addoutput(nidq_dg, "Dev27", "ao1", "Voltage"); % trigger




for block_nb = 1:2
    %     disp('started block')
    %     file_logic = 0;
    % cmd = sprintf('python %s && exit &', 'C:\Users\mouse1\Documents\GitHub\pySpinCapture\cameraCapturePulse.py');

    cmd = sprintf('python %s %d %s %d && exit &', 'C:\Users\mouse1\Documents\GitHub\pySpinCapture\cameraCapturePulse.py', pulse_dur, subject, block_nb);
    system(cmd);
    WaitSecs(5);

    %% Execute
    disp('start nidq')
    %disp(nidq.Rate)
    %disp(pulse_dur*nidq.Rate)
    start(nidq, "NumScans", pulse_dur*nidq.Rate);
    %behCam_pulses%(pulse_duration)%,nidq); %
    %pause(pulse_dur)

digital_out(nidq_dg, nidq_out_list, "airpuff", 4, 1) % Use start to initiate operations when counter output channels are configured.
pause(2)
digital_out(nidq_dg, nidq_out_list, "water",4, 1) % Use start to initiate operations when counter output channels are configured.



    %WaitSecs(3); % Must wait for the duration of pulsing (video recording)
    %     disp('end pulse')
    %     while file_logic < 1
%     currfiles=dir(fullfile('C:\video',recording_date));
%     file_logic = (cell2mat(cellfun(@(a) contains(a,[subject, '_', num2str(block_nb)]), {currfiles.name}, 'UniformOutput', 0)));
%     these_videos=struct2cell(currfiles);
%     this_video=these_videos(1,file_logic);
    %         WaitSecs(0.2);
    %     end
    %    disp('recorded')
    %pause(2)
    %
    %pause(20)
    %system('Taskkill/IM cmd.exe')
%     v=VideoReader(fullfile('C:\video',recording_date,this_video(end)));
%     disp(v.NumFrames)
    %system('Taskkill/IM cmd.exe')
    %pause(10)
    %     WaitSecs(5);
    %     disp('waited')
end