function ClosedLoop
close all
k = 0;
tp=task_state_class()
in_movement=false;
% figure
hold on;
parity_check = 0;
isBCI = -1;

fh = figure('Position',[1300 800 400 300])
%Configure sopt window
h = uicontrol('Style', 'PushButton', 'String', 'Stop BCI', ...
    'Callback', 'delete(gcbo)','Position',[100 100 200 100]);
%  fg = figure('Position',[1200 800 400 300])
%Configure sopt window
g = uicontrol('Style', 'PushButton', 'String', 'Switch BCI', ...
    'Callback',@myfunc,'Position',[100 200 200 100]);

cbmex('open')
cbmex('trialconfig',1)

start_time = now;
counter = 1;
max_trial_duration = 10; %[sec]
iteration_time_step = 0.001 %in [sec]
%the number 768 takes into account 6 units and 128 channels
spike_data = zeros(max_trial_duration/iteration_time_step,768);
elapsed_time = zeros(max_trial_duration/iteration_time_step,1);


d2s=@(t)t*86400;

s2d=@(t)t/86400;

%set_the waiting time in seconds
BCI_update_time = 0.03 %in secs
time_counter = BCI_update_time;

vrpn_server('start_server','Tracker0@127.0.0.1')
    
    vrpn_client('open_connection','Tracker10@127.0.0.1:6666')
    %vrpn_client('open_connection','Tracker0@127.0.0.1:5555')
   x = 0;
   y = 0; 


while ishandle(h)
    a=vrpn_client('get_positions','Tracker10@127.0.0.1:6666');
    [b,t]=vrpn_client('get_messages','Tracker10@127.0.0.1:6666');
    figure(1)
    if ~isempty(a)
   % vrpn_server('set_position', a(end,1),a(end,2),a(end,3))    
        if in_movement
            plot(a(:,1),a(:,2),'r.')
            
        else
            plot(a(:,1),a(:,2),'b.','MarkerSize',1)
        end
        plot(1000*x,1000*y,'xgreen')
    end
    
    if ~isempty(b)
        tp.parse_messages(b);
        
        if (tp.new_trial==1)
            if isfield(tp.parameters,'REFERENCE_DIRECTION')
                subplot(2,2,tp.parameters.REFERENCE_DIRECTION/90+1);
                hold on
            end
        end
        
        if (tp.new_stage==1) && (strcmp(tp.stage_type,'PRE_ACQUIRE_MEM_TGT'));
            disp(['MOVEMENT PERIOD START'])
            in_movement=true;
        end
        
        if (tp.new_stage==1) && (strcmp(tp.stage_type,'HOLD_MEM_TGT') || strcmp(tp.stage_type,'ERROR') && in_movement);
            disp(['MOVEMENT PERIOD END'])
            in_movement=false;
        end
        
    end
    xlim([-200 200])
    ylim([-200 200])
    
    %Collect spike data continously (very fast)
    drawnow
   pause(iteration_time_step)
    event_data = cbmex('trialdata',0);
    
    
    elapsed_time(counter) = d2s( now - start_time);
    
    
    A =  cell2mat(cellfun(@length,event_data(1:128,2:7),'UniformOutput', false));
    
    B = reshape(A',1,[]);
    
    spike_data(counter,1:length(B)) = B;
    
    %disp(['Elapsed Time:', num2str(elapsed_time(counter))])
    time_counter - elapsed_time(counter);
    
    %Extract decoding information every 30 ms
    if  (time_counter < elapsed_time(counter))
        time_counter = time_counter +  BCI_update_time;
        %counter
        %disp('ok')
        if (counter > 30)
        neuron1 = spike_data(counter,2) - spike_data(counter-30,2);
        neuron2 = spike_data(counter,3) - spike_data(counter-30,3);
        neuron3 = spike_data(counter,4)- spike_data(counter-30,4);
        neuron4 = spike_data(counter,9)- spike_data(counter-30,9);
        G = 1;
        Offset = 0;
        %implement Dummy decoder
        x = 10*(neuron2./BCI_update_time - neuron1./BCI_update_time)/8000; 
        y = 10*(neuron4./BCI_update_time - neuron3./BCI_update_time)/8000;
        
        x*1000;
        y*1000;
       vrpn_server('set_position',x,y,0);
        end
    end
    counter = counter +1;
    
    
    
   
  
    if (isBCI==1)
        vrpn_server('send_message','BCION')
      display('bci on')
      isBCI=-1;
    elseif (isBCI==0)
        vrpn_server('send_message','BCIOFF')
        display('bci off');
        isBCI=-1;
    end



pause(0.01)
drawnow
k=k+1;
end
cbmex('close')
vrpn_server('stop_server')
close all
function myfunc(hObj,event)

if mod(parity_check,2) == 0
    isBCI = 1;
else
    isBCI = 0;
end

parity_check = parity_check + 1;
end

end