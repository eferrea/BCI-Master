% %vrpn_server('start_server','Tracker0')
% %%test server
% vrpn_server('start_server','Tracker0@127.0.0.1')
% 
% close all
%% test client

tp=task_state_class();
fh = figure('Position',[1300 800 400 300])
%Configure sopt window
h = uicontrol('Style', 'PushButton', 'String', 'Stop BCI', ...
    'Callback', 'delete(gcbo)','Position',[100 100 200 100]);

%    vrpn_client('open_connection','Tracker10@127.0.0.1:5555')
%     vrpn_client('open_connection','Tracker0@127.0.0.1:5555')
client_address = 'Tracker20@172.17.6.10:6666'
% vrpn_client('open_connection','Tracker10@127.0.0.1:5555')
% vrpn_client('open_connection','Tracker10@172.17.6.10:6666')
vrpn_client('open_connection',client_address)

while ishandle(h)
    
    pause(0.01)
    %vrpn_client('get_positions','Tracker10@127.0.0.1:5555')
    % vrpn_client('get_positions','Tracker10@localhost')
    % vrpn_client('get_messages','Tracker10@127.0.0.1:6666')
    a=vrpn_client('get_positions',client_address);
    b=vrpn_client('get_messages',client_address);
    if ~isempty(a)
        a;
        b;
    end
    
    if ~isempty(b)
        tp.parse_messages(b);
        b
        
    end
    
    end
    %  vrpn_client('close_connection','Tracker0@127.0.0.1:5555')
    vrpn_client('close_connection',client_address)
    %  vrpn_server('stop_server')
    if ishandle(fh)
        close(fh)
    end
    
