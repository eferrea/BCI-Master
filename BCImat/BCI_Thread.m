function BCI_Thread(isBrain,neurons,dimensions,delay,use_eye_fixation)

clc
close all
%warning('off','MATLAB:singularMatrix')
opengl hardware
%% Initialize text file to store values
[year,month,day] =  ymd(datetime);
[hour,minute,second] = hms(datetime);
filename_root = [num2str(year) '-' num2str(month) '-' num2str(day) '_' num2str(hour) '-'  num2str(minute) '-'  num2str(int8(second))];
filename_track = [filename_root '_BCI_trackers.txt'];%to store position and speeds values
filename_task = [filename_root '_BCI_Task.txt'];%to store in matlab timings task controller values
filename_spikes = [filename_root '_spikes.txt'];%to store in matlab firing rates
fileID_track = fopen(filename_track,'at');
fileID_task = fopen(filename_task,'at');
fileID_spikes = fopen(filename_spikes,'at');

printfFormatTrackHeader = ['%6s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s\n'];
printfFormatTrackBody = ['%6.3f %12.6f %12.6f %12.6f %12.6f %12.6f %12.6f %12.6f %12.6f %12.6f %12.6f %12.6f %12.6f\n'];
fprintf(fileID_track,printfFormatTrackHeader,'time','pos_x','pos_y','pos_z','vel_x','vel_y','vel_z',...
    'BCI_pos_x','BCI_pos_y','BCI_pos_z','BCI_vel_x','BCI_vel_y','BCI_vel_z');
%header of task controller file
fprintf(fileID_task,'%6s %12s %25s %12s %12s %12s %12s %12s %12s %12s\n','time','Trial','Stage','BCI_on', 'IDLE_on', 'tgt_x','tgt_y','tgt_z','Hit', 'EYE_on');
printfFormatSpikesHeader = ['%6s' repmat('%6d ',1,767) '%6d\n'];
printfFormatSpikesBody = ['%6.4f' repmat('%6d ',1,767) '%6d\n']
fprintf(fileID_spikes,printfFormatSpikesHeader,'time',1:768);


%% Initialize values to switch betweeen MC and BC and buffers to store spike data
parity_check = 0;
isBCI = -1;
isIDLE = false;
decoder_on = false;
task_running = true;%value to run the loop
check_correlation = false; % check_correlation in IDLE_state;

%initialize Blackrock mex file for sending data
if (isBrain)
    cbmex('open');
    cbmex('trialconfig',1);
else
    %initialize Fake monkey (poisson process spike generator)
    fake_monkey= simNeurons_3D_velocity(neurons); % number of neurons
end
%set_the waiting time in seconds
BCI_update_time = 0.05 %in secs. As described in papers KF usually uses 50 ms.
counter = 1;
corr_counter =0;% this counter count the number of iterations per trial
internal_hit_counter =0;
max_trial_duration = 60;%[s] %used to initialize the maximum size of the buffer for spike data
max_experiment_duration = 10800;%in [sec]

%Inizialize data to store spikes the number 768 takes into account 6 units and 128 channels
spike_data = zeros(ceil(max_trial_duration/BCI_update_time),768);
%We want to store the time information for each trial
elapsed_time = zeros(ceil(max_trial_duration/BCI_update_time),1);

interval = 0;
%We want to store data coming from the task controller in matlab timings


%store in a table task parameters that will be used to dsave the data: the
%table is suitable for two reasons: ease of indexing entries and better
%readability of the code.
%task_buffer = cell(ceil(max_trial_duration/BCI_update_time),8);alternative
task_buffer =  table(nan(ceil(max_trial_duration/BCI_update_time),1),nan(ceil(max_trial_duration/BCI_update_time),1),...
    repmat({'none'},ceil(max_trial_duration/BCI_update_time),1),nan(ceil(max_trial_duration/BCI_update_time),1),...
    nan(ceil(max_trial_duration/BCI_update_time),1),nan(ceil(max_trial_duration/BCI_update_time),1),...
    nan(ceil(max_trial_duration/BCI_update_time),1),nan(ceil(max_trial_duration/BCI_update_time),1),...
    nan(ceil(max_trial_duration/BCI_update_time),1),nan(ceil(max_trial_duration/BCI_update_time),1),...
    'VariableNames',{'time' 'trial_index' 'stage_type' 'BCI_on' 'IDLE_on' 'tgt_x' 'tgt_y' 'tgt_z' 'Hit' 'EYE_on'});



%% initialize dynamical vectors
direction_vector = [0 0]; %to store directions of the target
velocity_vector = zeros(ceil(max_trial_duration/BCI_update_time),2); % used to simulate Poisson like
position_vector = zeros(ceil(max_trial_duration/BCI_update_time),2);
accelleration_vector = zeros(ceil(max_trial_duration/BCI_update_time),2);

%% define some inline function to retrieve right timings from the call to now
d2s=@(t)t*86400;
s2d=@(t)t/86400;

% % %% initialize VRPN matlab server
  %vrpn_server('start_server','Tracker0@172.17.6.10:5555')
% % % %initialize VRPN matlab client
  % vrpn_client('open_connection','Tracker10@127.0.0.1:6666') %same computer
% % %vrpn_client('open_connection','Tracker10@172.17.6.149:6666') %Pierre's Computer
% 
% 
vrpn_server('start_server','Tracker0@172.17.6.10')
% % %initialize VRPN matlab client
vrpn_client('open_connection','Tracker10@172.17.6.10:6666') %same computer
% % %vrpn_client('open_connection','Tracker10@127.0.0.1:6666') %same computer
% % %vrpn_client('open_connection','Tracker10@172.17.6.10:6666') %Pierre's Computer
 % vrpn_client('open_connection','Tracker10@172.17.6.10:6666') %my computer

%% initialize objects
tp=task_state_class();
tp.set_new_trial_callback(@(tmp)[]);
max_corr_samples = 200;
cal = Kalman_calibrator_class(dimensions,BCI_update_time,max_experiment_duration,delay);
bci = Kalman_decoder_class(dimensions,BCI_update_time,max_experiment_duration,delay,max_corr_samples);
perc = 0; % shared control starting value
%%  use a simple GUI to do the switch the function that get used (it is defined
% at the end of the code)
fh = figure('Position',[1300 200 1000 900]);
%Panel to put the switch and close BCI buttons
p = uipanel('Position',[0.89 0.75 .1 .25]);
%Configure stop window
h = uicontrol(p,'Style', 'PushButton', 'String', 'Stop BCI','Units','normalized',...
    'Callback', @StopBCI,'Position',[0 .01 1 .12]);
%Configure Switch window
g = uicontrol(p,'Style', 'PushButton', 'String', 'Switch BCI', 'Units','normalized',...
    'Callback',@SwitchBCI,'Position',[0 .14 1 .12]);

v = uicontrol(p,'Style', 'PushButton', 'String', 'UpdateDecoder', 'Units','normalized',...
    'Callback',@UpdateDecoder,'Position',[0 .27 1 .12]);

f = uicontrol(p,'Style', 'PushButton', 'String', 'Load Decoder', 'Units','normalized',...
    'Callback',@LoadDecoder,'Position',[0 .41 1 .12]);

u = uicontrol(p,'Style', 'PushButton', 'String', 'Update Regression', 'Units','normalized',...
    'Callback',@UpdateRegression,'Position',[0 .55 1 .12]);


%Configure Button Press
hndl=@(object,eventdata)mouseClick(cal,'WindowButtonDownFcn');
hndl1=@(object,eventdata)CheckCorrelation(bci,'PushButton');
%hndl1 = @(object,eventdata)mouseMove(cal,'WindowButtonMotionFcn');

hl1  = uicontrol(p,'Style', 'PushButton', 'String', 'Check Correlation','Units','normalized',...
    'Callback', hndl1,'Position',[0 .83 1 .12]);

%set (gcf, 'WindowButtonMotionFcn',hndl1);
set (gcf, 'WindowButtonDownFcn', hndl);

%create other panel to clear calibrator window
p1 = uipanel('Position',[0.89 0.55 .1 .15]);

%clear the calibrator window
h1 = uicontrol(p1,'Style', 'PushButton', 'String', 'Reset Decoder','Units','normalized',...
    'Callback', @ResetDecoder,'Position',[0 .01 1 .45]);
%clear the decoder window
g1 = uicontrol(p1,'Style', 'PushButton', 'String', 'Reset Calibrator', 'Units','normalized',...
    'Callback',@ResetCalibrator,'Position',[0 .52 1 .45]);

%%Log in the task controller the property of the fajke monkey
p2 = uipanel('Title','Shared Control','FontSize',8,'Position',[0.89 0.25 .1 .10])
g2 = uicontrol(p2,'style','edit',...
    'Units','normalized',...
    'Position',[0.1 0.1 0.8 0.8],...
    'foregroundcolor','black',...
    'callback',@Temp_call);
% perturabation panel
Control_perturbation(bci,cal,fh,0.1,0.01,0.3,0.3)

%% start to count the time
start_time = now;

%% while loop
while (task_running)
    %vrpn_server('send_message',cal.filename)
    %% This is used to measure the time that every iteration takes
    loop_start_time = now;
    %measure the global passing time
    elapsed_time(counter) = d2s( now - start_time);
    global_time =  d2s( now - start_time);
    %read robot/markers position from MOROCO
    a=vrpn_client('get_positions','Tracker10@172.17.6.10:6666'); %same
    %computer local
    %a=vrpn_client('get_positions','Tracker10@172.17.6.10:6666'); %my computer
    
    %read task controller state
    [b,t]=vrpn_client('get_messages','Tracker10@172.17.6.10:6666'); %same
    %computer local
    %[b,t]=vrpn_client('get_messages','Tracker10@172.17.6.10:6666'); %my computer
    %parse task controller messages
    tp.parse_messages(b)

    
    %% Generate spike data and flush spike buffer if a new trial has started.
    %Erase spike buffer and elapsed time counter.
    if tp.new_trial
        disp('new trial')
        %save everything from the previous trial at the beginning of the
        %current trial
        for i = 1: counter-1
            fprintf(fileID_task,'%6.3f %12d %25s %12d %12d %12.4f %12.4f %12.4f %12d %12d\n',task_buffer.time(i),  task_buffer.trial_index(i), char(task_buffer.stage_type{i}),...
                task_buffer.BCI_on(i),task_buffer.IDLE_on(i), task_buffer.tgt_x(i),task_buffer.tgt_y(i),task_buffer.tgt_z(i), task_buffer.Hit(i),task_buffer.EYE_on(i));
        end
        flush = 1;
        counter = 1;
        if (isBrain)
            cbmex('trialconfig',1)
        end
        spike_data = zeros(ceil(max_trial_duration/BCI_update_time),768);
        elapsed_time = zeros(ceil(max_trial_duration/BCI_update_time),1);
        
        %erase task controller table values to be saved online on txt file.
        task_buffer =  table(nan(ceil(max_trial_duration/BCI_update_time),1),nan(ceil(max_trial_duration/BCI_update_time),1),...
            repmat({'none'},ceil(max_trial_duration/BCI_update_time),1),nan(ceil(max_trial_duration/BCI_update_time),1),...
            nan(ceil(max_trial_duration/BCI_update_time),1),nan(ceil(max_trial_duration/BCI_update_time),1),...
            nan(ceil(max_trial_duration/BCI_update_time),1),nan(ceil(max_trial_duration/BCI_update_time),1),...
            nan(ceil(max_trial_duration/BCI_update_time),1),nan(ceil(max_trial_duration/BCI_update_time),1),...
            'VariableNames',{'time' 'trial_index' 'stage_type' 'BCI_on' 'IDLE_on' 'tgt_x' 'tgt_y' 'tgt_z' 'Hit' 'EYE_on'});
        
        
    else
        flush = 0;
    end
    %% store in a cell task controller parameters at every iteration step
    %store also the target position (not used for Kalman F)
    if ~isempty(tp.parameters)
        direction_vector(1) = tp.parameters.REFERENCE_X_DIRECTION;
        direction_vector(2) = tp.parameters.REFERENCE_Y_DIRECTION;
        %direction_vector(3) = tp.parameters.REFERENCE_Z_DIRECTION;
    end
    %display(global_time)
    % display(direction_vector)
    task_buffer.time(counter) = global_time;
    task_buffer.trial_index(counter) = tp.trial_index_TC;
    tp.trial_index_TC;
    if ~isempty(tp.stage_type)
        task_buffer.stage_type{counter}= {tp.stage_type};
    end
    task_buffer.BCI_on(counter) = decoder_on;
    task_buffer.IDLE_on(counter) = isIDLE;
    task_buffer.EYE_on(counter) = str2double(tp.iseye);
    task_buffer.tgt_x(counter) = direction_vector(1);
    task_buffer.tgt_y(counter) = direction_vector(2);
    %task_buffer.tgt_z(counter) = direction_vector(3);
    
    %% store the position of the cursor if available from the TC.
    if ~isempty(a)
        %upscale a by 1000 to have uniform measures
        position_vector(counter,:) =  a(end,1:2);%the counting is done on a trial basis.
        
        if (counter > 1)
            velocity_vector(counter,:) = (position_vector(counter,:) - position_vector(counter-1,:))./(elapsed_time(counter) - elapsed_time(counter-1));
            % velocity_vector(counter,:)
            % accelleration_vector(counter,:) = (velocity_vector(counter,:) - velocity_vector(counter-1,:))./(elapsed_time(counter) - elapsed_time(counter-1));
            
        end
    end
    
    %% ############ Generate the spikes##########
    if (isBrain)
        if counter > 1
            event_data = cbmex('trialdata',0);%real data
        else
            
            event_data = cell(128,7);
        end
    else
        % event_data = cbmex('trialdata',flush);%real data
        fake_monkey.generate_poisson(velocity_vector(counter,:),flush); % gernerate fake monkey data
        event_data = fake_monkey.poisson_spike;%store fake monkey data;
    end
    % disp(num2str(elapsed_time(counter)))
    %A =  cell2mat(cellfun(@length,event_data(1:128,2:7),'UniformOutput', false));
    A =  cellfun(@length,event_data(1:128,2:7));%take the length of each class element
    
    %arrange data in an Array of Firing rate
    B = A(:)'; %reshape(A',1,[]);%
    
    %Keep trace on a trial basis of the firing rate of neurons
    %spike_data(counter,1:length(B)) = B;
    spike_data(counter,1:768) = B;
    
    
    %% ##############Execute the main calibrator and BCI loops
    if counter > 1
        number_of_spikes = spike_data(counter,:) - spike_data(counter-1,:);
        interval =  elapsed_time(counter) - elapsed_time(counter-1);
    else
        number_of_spikes = spike_data(counter,:);
        interval =  elapsed_time(counter);
    end
    bci.loop(tp,global_time,interval,number_of_spikes,decoder_on,direction_vector,perc);
    %store variables for displaying correlation values in the IDLE mode.
    bci.OnlineCorrelation(tp,velocity_vector(counter,:)',decoder_on,isIDLE,check_correlation);
    %run a calibration step if the target was hit (inside the function regression is done at the reward stage)
    cal.loop(tp,global_time,interval,number_of_spikes,position_vector(counter,:)',velocity_vector(counter,:)',decoder_on,bci,direction_vector,use_eye_fixation);
    
    
    
    
    %% #########send info to task controller relative to BCI status,
    %update the decoder when calibration is done
    if (isBCI==1)
        vrpn_server('send_message','BCION')
        display('bci on')
        cal.UpdateDecoder(bci,decoder_on);
        decoder_on = true;
        isIDLE = true;
        isBCI=-1;
        vrpn_server('send_message',cal.filename)
    elseif (isBCI==0)
        vrpn_server('send_message','BCIOFF')
        display('bci off');
        decoder_on = false;
        isIDLE = false;
        isBCI=-1;
    end
    
    
    
    
    %% append values to file at every step
    fprintf(fileID_track,printfFormatTrackBody,[global_time position_vector(counter,:) velocity_vector(counter,:) bci.position(bci.sample-delay,:) bci.velocity(bci.sample-delay,:)]);
    fprintf(fileID_spikes,printfFormatSpikesBody,[global_time number_of_spikes]);
    %disp( num2str(bci.velocity(bci.sample,:)))
    
    %% Save task controller data at the end of the trial
    if strcmp(tp.stage_type,'ERROR')  %&& tp.new_stage
        task_buffer.Hit(1:counter) = 0;
        % for i = 1: counter
        %  fprintf(fileID_task,'%6.6f %12d %12s %12d %12.4f %12.4f %12.4f  %12d\n',task_buffer.time(i),  task_buffer.trial_index(i), char(task_buffer.stage_type{i}),...
        %      task_buffer.BCI_on(i),task_buffer.tgt_x(i),task_buffer.tgt_y(i),task_buffer.tgt_z(i), task_buffer.Hit(i) );
        % end
        % fprintf(fileID_track,'%d %d %s %d %d %d %d %d\n',...
        %     [task_buffer{1:counter,1},task_buffer{1:counter,2},task_buffer{1:counter,3},task_buffer{1:counter,4},...
        %     task_buffer{1:counter,5},task_buffer{1:counter,6},task_buffer{1:counter,7},task_buffer{1:counter,8}]);
    elseif strcmp(tp.stage_type,'REWARD')
        task_buffer.Hit(1:counter) = 1;
        %      for i = 1: counter
        %  fprintf(fileID_task,'%6.6f %12d %12s %12d %12.4f %12.4f %12.4f  %12d\n',task_buffer.time(i),  task_buffer.trial_index(i), char(task_buffer.stage_type{i}),...
        %      task_buffer.BCI_on(i),task_buffer.tgt_x(i),task_buffer.tgt_y(i),task_buffer.tgt_z(i), task_buffer.Hit(i) );
        % end
        % fprintf(fileID_track,'%d %d %s %d %d %d %d %d\n',...
        %     [task_buffer{1:counter,1},task_buffer{1:counter,2},task_buffer{1:counter,3},task_buffer{1:counter,4},...
        %     task_buffer{1:counter,5},task_buffer{1:counter,6},task_buffer{1:counter,7},task_buffer{1:counter,8}]);
    end
    %     %% Output the actual decoder performances
    %     if(decoder_on) && (strcmp(tp.stage_type,'ACQUIRE_MEM_TGT') || strcmp(tp.stage_type,'HOLD_MEM_TGT'))
    %         corr_counter = corr_counter+1;
    %         vx(corr_counter) =  velocity_vector(counter,1);
    %         vy(corr_counter) =  velocity_vector(counter,2);
    %         vz(corr_counter) =  velocity_vector(counter,3);
    %
    %         vx_bci(corr_counter) = bci.velocity(bci.sample-delay,1);
    %         vy_bci(corr_counter) = bci.velocity(bci.sample-delay,2);
    %         vz_bci(corr_counter) = bci.velocity(bci.sample-delay,3);
    %
    %         if(tp.new_stage && (strcmp(tp.stage_type,'ACQUIRE_MEM_TGT')))
    %             internal_hit_counter = internal_hit_counter +1
    %
    %         end
    %
    %         % display correlation values every ten trials
    %         if(internal_hit_counter == 10)
    %            % check_correlation = false;
    %             rx = corr(vx(1:corr_counter)',vx_bci(1:corr_counter)');
    %               ry = corr(vy(1:corr_counter)',vy_bci(1:corr_counter)');
    %                 rz = corr(vz(1:corr_counter)',vz_bci(1:corr_counter)');
    %
    %             disp(['rx: ' num2str(rx) ' ry:' num2str(ry) ' rz:' num2str(rz)])
    %            internal_hit_counter =0
    %            corr_counter = 0;;
    %         end
    %
    %
    %     end
    %% Calculate the duration of the loop so far
    loop_end_time = d2s( now - loop_start_time);
    waiting_time = BCI_update_time-loop_end_time; %how much time is left from the iteration time?
    %Finally update the iteration counter
    %display(waiting_time)
    bci.SaveDecoder();
    counter = counter +1;
    pause(waiting_time) %wait the additional amount of time
end

%Close the cbmex connection and vrpn connection
cbmex('close')
vrpn_server('stop_server')
close all

%this is the function called once we press the button
    function SwitchBCI(hObj,event)
        
        if mod(parity_check,2) == 0
            
            isBCI = 1;
            
        else
            isBCI = 0;
        end
        
        parity_check = parity_check + 1;
    end

    function UpdateRegression(hObj,event)
        
        
        cal.UpdateRegression(decoder_on);
        reshaped_correlation = reshape(cal.correlation_tuning,128,6);
        active_neurons = cal.neurons;
        display_table(fh,0.45, 0.00, .42, 1,cal,cal);
        
        
        display_array_properties(0.01, 0.35, .42, .6,reshaped_correlation',active_neurons');
    end

    function LoadDecoder(hObj,event)
        
        
        cal.LoadDecoder(bci);
        reshaped_correlation = reshape(cal.correlation_tuning,128,6);
        active_neurons = cal.neurons;
        display_table(fh,0.45, 0.00, .42, 1,cal,cal);
        
        
        display_array_properties(0.01, 0.35, .42, .6,reshaped_correlation',active_neurons');
    end

    function UpdateDecoder(hObj,event)
        
        
        cal.UpdateDecoder(bci,decoder_on);
        reshaped_correlation = reshape(cal.correlation_tuning,128,6);
        active_neurons = cal.neurons;
        display_table(fh,0.45, 0.00, .42, 1,cal,cal);
        display_array_properties(0.01, 0.35, .42, .6,reshaped_correlation',active_neurons');
        vrpn_server('send_message',cal.filename)
    end

    function ResetCalibrator(hObj,event)
        
        cal.ResetCalibrator();
        
    end

    function ResetDecoder(hObj,event)
        
        bci.ResetDecoder();
    end



    function Temp_call(src,eventdata)
        str=get(src,'String')
        
        if isempty(str2num(str))
            set(src,'string','0');
            str=get(src,'String');
            warning('Input must be numerical');
        end
        
        if ~isempty(str2num(str)) && (str2num(str) <0 || str2num(str) >1)
            set(src,'string','0');
            str=get(src,'String')
            warning('Input must be numerical between 0 AND 1');
        end
        perc =  str2num(str);
        display(perc)
        vrpn_server('send_message',['SC_' str])
    end



    function StopBCI(hObj,event)
        bci.SaveDecoder();
        delete(bci) %destructor
        delete(cal) %destructor
        fclose(fileID_track);
        fclose(fileID_task);
        fclose(fileID_spikes);
        task_running = false;
    end





end