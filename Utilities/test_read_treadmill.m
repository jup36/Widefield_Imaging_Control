%test_treadmill_read

nidq = daq("ni");
nidq.Rate = 100; % 300KHz
addinput(nidq, "Dev1", "ai0", "Voltage");

%%
data = read(nidq, seconds(5));

%%
speed= convertJaneliaTreadmillVoltToSpeed(data.Dev1_ai0);
figure
plot(data.Time,speed)

%%
axis([0 10 -5 5])

xlabel('Tid (s)');

ylabel('Amplitude (V)');

h=animatedline;

start(nidq,"NumScans",1000)

count_scan=1;
while nidq.Running
    pause(0.5)
    fprintf("While loop: Scans acquired = %d\n", nidq.NumScansAcquired)
    data=read(nidq,"all");
        y = data.Dev1_ai0;
        x = (count_scan:count_scan+length(data.Dev1_ai0)-1)/nidq.Rate;
        addpoints(h,x,y);
        drawnow
        count_scan=count_scan+length(data.Dev1_ai0)-1;
end


%%
%%


% 
% WaitSecs(1);
% for k = 1:500
%     data = read(nidq,"all");
%     x = k/nidq.Rate;
%     y = data.Dev1_ai0;
%     addpoints(h,x,y(k));
%     drawnow
% end
% 
% 
% %%
% h = animatedline;
% axis([0 4*pi -1 1])
% x = linspace(0,4*pi,2000);
% 
% for k = 1:length(x)
%     y = sin(x(k));
%     addpoints(h,x(k),y);
%     drawnow
% end
