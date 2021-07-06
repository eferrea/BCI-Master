fake_monkey = simNeurons_3D_velocity(70);



d2s=@(t)t*86400;
s2d=@(t)t/86400;
interval = ones(1,400);
for i = 1 : length(interval)
     elapsed_time = now;
fake_monkey.generate_poisson([1 1 1],0); % gernerate fake monkey data
    event_data = fake_monkey.poisson_spike;%store fake monkey data;
   
    
     %loop_end_time = d2s( now - elapsed_time)
     loop_end_time = d2s( now - elapsed_time);
    interval(i) = 0.05-loop_end_time; %how much time is left from the iteration time?
    
    %Finally update the iteration counter
   
    pause(interval) %wait the additional amount of time 

    
end

plot(0.05 -interval)
