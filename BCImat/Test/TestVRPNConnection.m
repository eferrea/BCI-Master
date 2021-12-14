%Check if VRPN messages and cursor positions are transmitted
%@ E.Ferrea, 2015

tp=task_state_class();
fh = figure('Position',[1300 800 400 300])
h = uicontrol('Style', 'PushButton', 'String', 'Stop BCI', ...
    'Callback', 'delete(gcbo)','Position',[100 100 200 100]);
   
server = 'TrackerTC@127.0.0.1:6666';%local computer
    vrpn_client('open_connection',server)
   
    
   
    while ishandle(h)
        
        pause(0.02)

      b=vrpn_client('get_messages',server); 
      a=vrpn_client('get_positions',server)
      
%       if ~isempty(b)
%          
%        % tp.parse_messages(b);
%           %b
%       end
      
    end

vrpn_client('close_connection',server)
  %  vrpn_server('stop_server')
    if ishandle(fh)
    close(fh)
end
    
    