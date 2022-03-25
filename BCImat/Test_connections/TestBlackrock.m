%test connection with Blackrock cereplex system
%Check that spike_data get filled during signal acquisition
%@ E. Ferrea,  2015

%this code snipped is based on how to read online data from cereplex system
%https://blackrockneurotech.com/research/wp-content/ifu/LB-0590-3.00-cbMEX-IFU.pdf
%the code reads spikes data for 5 seconds and restructure the data as used
%inside BCI mat. Importantly you must check that if spikes are recorded the
%buffer is not empty.
clc
cbmex('open') %open connection with cerebus system
cbmex('trialconfig',1)
cbmex('mask',2,1)
pause(5)
event_data = cbmex('trialdata',1)
cbmex('close')

temp =  cellfun(@length,event_data(1:128,2:7));%read data streamed from recording system

temp1 = temp(:)'; %reshape(A',1,[]);%

spike_data(1,1:length(temp1)) = temp1;

BCImat_format = reshape(spike_data,128,6);