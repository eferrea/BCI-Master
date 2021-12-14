%test connection with Blackrock cereplex system
%Check that spike_data get filled during signal acquisition  
%@ E. Ferrea,  2015
clc
cbmex('open')
cbmex('trialconfig',1)
cbmex('mask',2,1)
pause(5)
event_data = cbmex('trialdata',1)
cbmex('close')

 A =  cellfun(@length,event_data(1:128,2:7));%to fit 3D Poisson spike class
    
    B = A(:)'; %reshape(A',1,[]);%
    
    spike_data(1,1:length(B)) = B;
    
    s = reshape(spike_data,128,6)