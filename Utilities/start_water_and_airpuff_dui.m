%turn on water and air puff at the start of the day
% "dur_sec": The duration for digital line "high" in sec

dui = serialport("COM4", 9600);

configureTerminator(dui,"CR/LF");

dui.UserData=struct("Data",[],"Count",1);
configureCallback(dui,"terminator", @readSerialData)


%% Flush
write(dui, "F", "char" ); %doesn't matter what we send, just not P or R

%% One drop
write(dui, "D", "char" ); %doesn't matter what we send, just not P or R

%% 100 drop
write(dui, "H", "char" ); %doesn't matter what we send, just not P or R0.79mL

%% Airpuff
write(dui, "P", "char" ); %doesn't matter what we send, just not P or R


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
% % FLUSH water with dui
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
write(dui, "R", "char" ); %doesn't matter what we send, just not P or R
WaitSecs(5)
write(dui, "O", "char" );
% 
