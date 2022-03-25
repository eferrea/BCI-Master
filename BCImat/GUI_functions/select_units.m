%% to display and select units from GUI
% @E.Ferrea,2015
function select_units (object, eventdata)

%INPUT:

%object: it takes the calibrator object as input and set the neurons that are used for decodding
%eventdata:it defines the type of Matlab GUI. It should be 'WindowButtonDownFcn'

%%
C = get (gca, 'CurrentPoint');
activated_channel = int16(C(1,1));
activated_unit = int16(C(1,2));

object.set_neurons(activated_channel,activated_unit)
display(num2str((C(1,1:2))))
title(gca, ['(Ch,U) = (', num2str(int16(C(1,1))), ', ',num2str(int16(C(1,2))), ')']);


end