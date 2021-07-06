function DecoderState(h,x_pos,y_pos,x_lenght,y_length)
%initialize values

%h = figure;
p_decoder_state = uipanel('Parent',h,'Title','Perturbation Panel','FontSize',10,'Units','normalized',...
    'Position',[x_pos y_pos x_lenght y_length]);
p_decoder_on=  uicontrol(p,'Style', 'PushButton', 'String', 'Check Correlation','Units','normalized',...
    'Callback', hndl1,'Position',[0 .83 1 .12]);
p_decoder_off =  uicontrol(p,'Style', 'PushButton', 'String', 'Check Correlation','Units','normalized',...
    'Callback', hndl1,'Position',[0 .83 1 .12]);



    function DecoderOn(p,eventdata)
        p = true;
        display('decoder forced to be ON')
       
    end


    function DecoderOff(p,eventdata)
      p = false
            display('decoder forced to be OFF');
        end
        
        