function SelectUnits (object, eventdata)
%function mouseClick (object)

C = get (gca, 'CurrentPoint');
activated_channel = int16(C(1,1));
activated_unit = int16(C(1,2));

object.set_neurons(activated_channel,activated_unit)
%display(num2str(int16(C(1,1:2))))
title(gca, ['(Ch,U) = (', num2str(int16(C(1,1))), ', ',num2str(int16(C(1,2))), ')']);
 

end