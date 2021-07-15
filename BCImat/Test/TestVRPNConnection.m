%Configure sopt window

tp=task_state_class();
fh = figure('Position',[1300 800 400 300])
h = uicontrol('Style', 'PushButton', 'String', 'Stop BCI', ...
    'Callback', 'delete(gcbo)','Position',[100 100 200 100]);
   
%    vrpn_client('open_connection','Tracker10@127.0.0.1:5555')
%     vrpn_client('open_connection','Tracker0@127.0.0.1:5555')

   % vrpn_client('open_connection','Tracker10@127.0.0.1:5555')
    vrpn_client('open_connection','Tracker10@172.17.6.10:6666')
   % vrpn_client('open_connection','Tracker10@127.0.0.1:6666') % local
   % computer
    
   %vrpn_client('open_connection','Tracker10@172.17.3.66:6666') %Michael Computer
    while ishandle(h)
        
        pause(0.02)
     %vrpn_client('get_positions','Tracker10@127.0.0.1:5555')
      % vrpn_client('get_positions','Tracker10@localhost')
      % vrpn_client('get_messages','Tracker10@127.0.0.1:6666')
      %a=vrpn_client('get_positions','Tracker10@127.0.0.1:6666');
      b=vrpn_client('get_messages','Tracker10@172.17.6.10:6666'); %local computer
      a=vrpn_client('get_positions','Tracker10@172.17.6.10:6666') %local computer
      
      %b=vrpn_client('get_messages','Tracker10@172.17.3.66:6666'); %Michael computer
      if ~isempty(b)
         
       % tp.parse_messages(b);
          %b
      end
      
    end
  %  vrpn_client('close_connection','Tracker0@127.0.0.1:5555')
vrpn_client('close_connection','Tracker10@172.17.6.10:6666')
  %  vrpn_server('stop_server')
    if ishandle(fh)
    close(fh)
end
    
    