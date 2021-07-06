function testButton
parity_check = 0;
isBCI = false;

figure('Position',[1200 800 400 300]);
%Configure sopt window
h = uicontrol('Style', 'PushButton', 'String', 'Stop BCI', ...
    'Callback', 'delete(gcbo)','Position',[100 100 200 100]);
%  fg = figure('Position',[1200 800 400 300])
%Configure sopt window
uicontrol('Style', 'PushButton', 'String', 'Switch BCI', ...
    'Callback', @myfunc,'Position',[100 200 200 100]);


    function myfunc(hObj,event)
        if mod(parity_check,2) == 0
            isBCI = true
        else
            isBCI = false
        end
        
        
        
        parity_check = parity_check + 1;
    end

end