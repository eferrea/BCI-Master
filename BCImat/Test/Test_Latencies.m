%% V1
elapsed_time = 0
start_time = tic
counter = 1;
delay = zeros(1,300);
elapsed_time = zeros(1,300);
while elapsed_time < 4 
pause(0.001)
elapsed_time(counter) = toc(start_time);
if counter > 1
delay(counter) = elapsed_time(counter) - elapsed_time(counter-1);
end
counter = counter +1;

end

%% V2

elapsed_time = zeros(1,1000);
for counter =1:1000
    tic
pause(0.001)
elapsed_time(counter) = toc;


end
figure

hist(elapsed_time,100)