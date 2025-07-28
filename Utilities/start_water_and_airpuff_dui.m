%turn on water and air puff at the start of the day
% "dur_sec": The duration for digital line "high" in sec
duiW = serialport("COM6", 9600);
%dui = serialport("COM5", 9600);

%% Flush
write(duiW, "F", "c\har" );

% long flush (25s)
write(duiW, "f", "char" ); % short flush (5s)

%% One drop
write(duiW, "D", "char" ); 

%% 100 drop
write(duiW, "H", "char" ); 

%% Airpuff
write(duiW, "P", "char" ); 

%% Water spout in 
write(dui, "I", "char" ); 

% %Get the water and air through the tubes
% % create a nidq object
% nidq = daq("ni");
% nidq.Rate = 3*1e5; % can't be at max, reducing to min 2*max freq of auditory stim
% 
% addoutput(nidq, "Dev27", "Port0/Line8", "Digital"); % airpuff
% addoutput(nidq, "Dev27", "Port0/Line9", "Digital"); % water
% addoutput(nidq, "Dev27", "ao1", "Voltage"); % trigger
% 
% nidq_out_list=["airpuff","water","trigger"];
% 
% % create an Arduino object
% a = arduino('COM4', 'uno');
% waterpin = 'D2';
% airpin = 'D3';
% switchpin = 'D4'; 
% lickpin = 'D8';
% 
% configurePin(a, lickpin,'DigitalInput')   % lickometer
% configurePin(a, switchpin,'DigitalInput') % switch (D2F-FL)
% configurePin(a, waterpin,'DigitalOutput') % water
% configurePin(a, airpin,'DigitalOutput')   % airpuff
% 
% %% FLUSH
% dur_sec=20;
% 
% % % Specify the # of scans
% % scans = nidq.Rate * dur_sec;
% %
% % % FLUSH with nidq
% % % Specify signal_out as M X N double matrix (M: # of scans, N: # of channels)
% % signal_out = zeros(round(scans), length(nidq_out_list));
% % signal_out (:, 1) = 1; % col1: air, col2: water
% % signal_out = [signal_out; zeros(1, length(nidq_out_list))]; % ensure to end with zeros to turn it off!
% %
% % write(nidq, signal_out)
% 
% % FLUSH water with duiW
% tic;
% while toc < dur_sec
%     writeDigitalPin(a,waterpin,1)
% end
% writeDigitalPin(a,waterpin,0)
% 
% %% Calibrate the water (remove comments to run)
% 
% % %Specify the # of scans
% % scans = round(nidq.Rate * dur_trial);
% % 
% % for t=1:3
% %     WaitSecs(2);
% %     %Specify signal_out as M X N double matrix (M: # of scans, N: # of channels)
% %     signal_out = zeros(round(scans), length(nidq_out_list));
% %     signal_out (:, 2) = 1;
% %     signal_out = [signal_out; zeros(1, length(nidq_out_list))]; % ensure to end with zeros to turn it off!
% % 
% %     write(nidq, signal_out)
% % end
% 
% dur_trial=0.02;
% 
% for t=1:3
%     WaitSecs(2);
%     tic;
%     while toc < dur_trial
%         writeDigitalPin(a,waterpin,1)
%     end
%     writeDigitalPin(a,waterpin,0)
% 
% end
% 
% %% test airpuff
% 
% dur_air=0.2;
% 
% for t=1:3
%     WaitSecs(2);
%     tic;
%     while toc < dur_air
%         writeDigitalPin(a,airpin,1)
%     end
%     writeDigitalPin(a,airpin,0)
% 
% end

%% test 
write(duiW, "R", "char" ); 
WaitSecs(5)
write(duiW, "O", "char" );
% 
