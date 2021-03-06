function control_perturbation(obj_dec,obj_cal,h,x_pos,y_pos,x_lenght,y_length)
% this function display a GUI to perturb the preferred direction of a subset of units parameters ,
% It rotates the preferred direction of a subset of units corresponding to the selected percentage
%It contains several subfunctions to implement the overall GUI functionality.

%INPUT:

%obj_dec: name of the decoder object.
%obj_cal: name of the calibrator object.
%h:figure object handle.
%x_pos: horizontal position of the window.
%y_pos: vertical position of the window.
%x_length: window length in the horizontal dimension.
%y_length: window length in the vertical dimension.


%@ E.Ferrea, 2017
%initialize values
perturbation_vector = zeros(1,3);
perturbation_angle = 0;
perturbation_percent = 0;

%h = figure;
p_perturb = uipanel('Parent',h,'Title','Perturbation Panel','FontSize',10,'Units','normalized',...
    'Position',[x_pos y_pos x_lenght y_length]);
p_vector = uipanel('Parent',p_perturb,'Title','Vector','FontSize',10,'Units','normalized',...
    'Position',[.01 .5 .99 .5]);
%% p_X, p_Y and P_Z are used to implement rotations in 3D
% p_X = uipanel('Parent',p_vector,'Title','X','FontSize',8,'Units','normalized',...
%     'Position',[.02 .01 .31 .9]);
% uicontrol(p_X,'style','edit',...
%     'Units','normalized',...
%     'Position',[0.1 0.1 0.8 0.8],...
%     'foregroundcolor','black',...
%     'callback',@set_X);
% 
% p_Y = uipanel('Parent',p_vector,'Title','Y','FontSize',8,'Units','normalized',...
%     'Position',[.35 .01 .31 .9]);
% 
% uicontrol(p_Y,'style','edit',...
%     'Units','normalized',...
%     'Position',[0.1 0.1 0.8 0.8],...
%     'foregroundcolor','black',...
%     'callback',@set_Y);
% 
% p_Z = uipanel('Parent',p_vector,'Title','Z','FontSize',8,'Units','normalized',...
%     'Position',[.68 .01 .31 .9]);
% 
% uicontrol(p_Z,'style','edit',...
%     'Units','normalized',...
%     'Position',[0.1 0.1 0.8 0.8],...
%     'foregroundcolor','black',...
%     'callback',@set_Z);

p_angle = uipanel('Parent',p_perturb,'Title','Angle','FontSize',8,'Units','normalized',...
    'Position',[0.02 0.2 .31 .3]);
uicontrol(p_angle ,'style','edit',...
    'Units','normalized',...
    'Position',[0.01 0.01 0.99 0.99],...
    'foregroundcolor','black',...
    'callback',@set_angle);

p_percentage = uipanel('Parent',p_perturb,'Title','% Rotation','FontSize',8,'Units','normalized',...
    'Position',[0.33 0.2 .6 .3]);
uicontrol(p_percentage ,'style','edit',...
    'Units','normalized',...
    'Position',[0.01 0.01 0.99 0.99],...
    'foregroundcolor','black',...
    'callback',@set_percent_rotation);

st = uicontrol('Parent',p_perturb,'String','Start','Units','normalized',...
    'Position',[0.01 0.001 0.49 0.2],'callback',@start_perturbation);

sp = uicontrol('Parent',p_perturb,'String','Stop','Units','normalized',...
    'Position',[0.50 0.001 0.49 0.2],'callback',@stop_perturbation);

%set rotation amount around x
%     function set_X(src,eventdata)
%         %INPUT:
%         %src: input string with numerical data
%         %eventdata: reserved - to be defined in a future version of MATLAB
%         
%         str=get(src,'String');
%         
%         if isempty(str2num(str))
%             set(src,'string','0');
%             str=get(src,'String');
%             warning('Input must be numerical');
%         end
%         
%         if ~isempty(str2num(str)) && (str2num(str) <0 || str2num(str) >1)
%             set(src,'string','0');
%             str=get(src,'String');
%             warning('Input must be numerical between 0 AND 1');
%         end
%         perturbation_vector(1) =    str2num(str);
%         %          perturbation_vector = perturbation_vector./norm(perturbation_vector);
%         %          set(src,'string',num2str(perturbation_vector(1)));
%         display(perturbation_vector)
%         % vrpn_server('send_message',['SC_' str])
%     end

% %set rotation amount around y
%     function set_Y(src,eventdata)
%         %INPUT:
%         %src: input string with numerical data
%         str=get(src,'String');
%         
%         if isempty(str2num(str))
%             set(src,'string','0');
%             str=get(src,'String');
%             warning('Input must be numerical');
%         end
%         
%         if ~isempty(str2num(str)) && (str2num(str) <0 || str2num(str) >1)
%             set(src,'string','0');
%             str=get(src,'String');
%             warning('Input must be numerical between 0 AND 1');
%         end
%         perturbation_vector(2) =    str2num(str);
%         %          perturbation_vector = perturbation_vector./norm(perturbation_vector);
%         %          set(src,'string',num2str(perturbation_vector(2)));
%         display(perturbation_vector)
%         % vrpn_server('send_message',['SC_' str])
%     end
% 
% 
% %set rotation amount around z
%     function set_Z(src,eventdata)
%         %INPUT:
%         %src: input string with numerical data
%         str=get(src,'String');
%         
%         if isempty(str2num(str))
%             set(src,'string','0');
%             str=get(src,'String');
%             warning('Input must be numerical');
%         end
%         
%         if ~isempty(str2num(str)) && (str2num(str) <0 || str2num(str) >1)
%             set(src,'string','0');
%             str=get(src,'String');
%             warning('Input must be numerical between 0 AND 1');
%         end
%         perturbation_vector(3) =    str2num(str);
%         display(perturbation_vector)
%         % vrpn_server('send_message',['SC_' str])
%     end

%set rotation angle
    function set_angle(src,eventdata)
        
        %INPUT:
        
        %src: input string with numerical data
        %event: reserved - to be defined in a future version of MATLAB
        
        str=get(src,'String');
        
        if isempty(str2num(str))
            set(src,'string','0');
            str=get(src,'String');
            warning('Input must be numerical');
        end
        
%         if ~isempty(str2num(str)) && (str2num(str) <0 || str2num(str) >90)
%             set(src,'string','0');
%             str=get(src,'String');
%             warning('Input must be numerical between 0 AND 90 degrees');
%         end

%         if ~isempty(str2num(str))
%             set(src,'string','0');
%             str=get(src,'String');
%             warning('Input must be numerical between 0 AND 90 degrees');
%         end
        perturbation_angle =    str2num(str);
        perturbation_angle =    round(perturbation_angle);
        set(src,'string',num2str(perturbation_angle));
        display(perturbation_angle)
        % vrpn_server('send_message',['SC_' str])
    end
%set percentage of units to be roated (e.g. preferred direction rotation)
    function set_percent_rotation(src,eventdata)
        
        %INPUT:
        
        %src: input string with numerical data
        %eventdata: reserved - to be defined in a future version of MATLAB
        
        str=get(src,'String');
        
        if isempty(str2num(str))
            set(src,'string','0');
            str=get(src,'String');
            warning('Input must be numerical');
        end
        
        if ~isempty(str2num(str)) && (str2num(str) <0 || str2num(str) >100)
            set(src,'string','0');
            str=get(src,'String');
            warning('Input must be numerical between 0 AND 100 degrees');
        end
        perturbation_percent =    str2num(str);
        perturbation_percent =    round(perturbation_percent);
        set(src,'string',num2str(perturbation_percent));
        display( perturbation_percent)
        % vrpn_server('send_message',['SC_' str])
    end

%start the rotation
    function start_perturbation(hObj,event)
        
        %INPUT:
        
        %hObj: handle object
        %event: reserved - to be defined in a future version of MATLAB
        display('Start perturbation')
         reshaped_correlation = reshape(obj_cal.correlation_tuning,128,6);
         st.ForegroundColor = 'red';
         % active_neurons = obj_cal.neurons;
        %obj_dec.ResetRotation(reshaped_correlation);
         %obj_dec.UpdateRotation(reshaped_correlation,perturbation_vector,perturbation_angle,perturbation_percent); %for 3D
         obj_dec.update_rotation(reshaped_correlation,perturbation_angle,perturbation_percent);
        
        
    end
%stop the rotation 
    function stop_perturbation(hObj,event)
        
        %INPUT:
        
        %hObj: handle object
        %event: reserved - to be defined in a future version of MATLAB
        display('Stop perturbation')
         reshaped_correlation = reshape(obj_cal.correlation_tuning,128,6);
         st.ForegroundColor = 'black';
        obj_dec.reset_rotation(reshaped_correlation);
        
        
    end



end
