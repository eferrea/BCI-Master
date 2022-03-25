% to display correlation values between real and decoded movemnets in the idle mode
% @E.Ferrea,2015
function check_correlation (object, eventdata)


%INPUT:

%object:take decoder object name as input and display check Pearson Correlation coefficients
%eventdata:it defines the type of Matlab GUI. It should be 'PushButton'

%%
object.check_correlation = true;
disp('Check Correlation')

end