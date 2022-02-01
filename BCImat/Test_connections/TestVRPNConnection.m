%% Check if VRPN messages and cursor positions are transmitted
%@ E.Ferrea, 2015
function TestVRPNConnection(server_address,ismessage)

%% INPUT:
%server_address: a vrpn server address from where to read the data;
%ismessage: if =1 display messages read from the server, if =0
%display curosr position

%%

fh = figure('Position',[1300 800 400 300])
h = uicontrol('Style', 'PushButton', 'String', 'Stop BCI', ...
    'Callback', 'delete(gcbo)','Position',[100 100 200 100]);

vrpn_client('open_connection',server_address)



while ishandle(h)
    
    pause(0.02)
    %read messages and positions from server
    message= vrpn_client('get_messages',server_address);
    position =vrpn_client('get_positions',server_address);
    %display messages or positions
    if(ismessage)
        display(message)
    else
        display(position)
    end
    
    
end

vrpn_client('close_connection',server_address)
%  vrpn_server('stop_server')
if ishandle(fh)
    close(fh)
end

end
    