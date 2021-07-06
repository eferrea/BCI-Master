%Calculate poisson distribution in a interval
clear spikes
rate =35; % firing rate [Hz]
dt= .001; % time between two bins
duration =1; % duration of simulation[ ms ]

counter = 1

for i =0: dt : duration 
if rand<=rate*dt
    
spikes(counter)=i; 

counter = counter +1;
end
end

stem(spikes,ones(1,length(spikes)))

%%


A = zeros(10,1/dt);

r = 10;
dt = 1/30000;
A(find(rand(10,1/dt) < r*dt)) = 1