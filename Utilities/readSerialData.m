function readSerialData(src,~)
        data = readline(src); % Read the data from Arduino as uint8
        src.UserData.Data(end+1)=str2double(data);
        src.UserData.Count=src.UserData.Count+1;

        outcome = str2double(char(data)); % Convert the received uint8 data to a number
        if outcome==1
            fprintf('Reward\n'); % Display the received value
        elseif outcome==2
            fprintf('Air Puff\n'); % Display the received value
        elseif outcome==3
            fprintf('Manual reward\n'); % Display the received value
        end
end



% function readSerialData(~,~)
%     global OUTCOME_COUNTER;
%     if dui.NumBytesAvailable > 0
%         data = read(dui, 1, "uint8"); % Read the data from Arduino as uint8
%         outcome = str2double(char(data)); % Convert the received uint8 data to a number
%         if outcome==1
%         fprintf('Reward\n'); % Display the received value
%         elseif outcome==2
%         fprintf('Air Puff\n'); % Display the received value
%         end
%         OUTCOME_COUNTER(outcome)=OUTCOME_COUNTER(outcome)+1;
%     end
% end
