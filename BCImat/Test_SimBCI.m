%%
clear all;
simNeuron = SimBCI(20); % number of neurons
tstart = tic;
sim_duration = 1; % simulation duration in secs
elapsed_time = 0;
while elapsed_time < sim_duration 
simNeuron.generate_poisson(45,0);  % degree and mode
elapsed_time = toc(tstart)
end

%% 
PD=simNeuron.True_PD;

%%
clear all;
simNeuron = SimBCI(20); % number of neurons
simNeuron.generate_poisson(45,1); 
s = simNeuron.poisson_spike;


%%
clear all;
simNeuron = SimBCI(20); % number of neurons
simNeuron.generate_poisson(45,0); 
s = simNeuron.poisson_spike;