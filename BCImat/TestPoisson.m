% lambda = 1;
% 
% x = 0:15;
% 
% y1 = lambda.^(x)./factorial(x)*exp(-lambda);
% 
% y = poisspdf(x,lambda);
% figure(1)
% plot(x,y,'+')
% figure(2)
% 
% plot(x,y1,'+')
 %% Test Poisson timestamps
clear all
close all
clc
sim_time = 10 % sec
start_time = tic;
elapsed_time = zeros(1,100000);
elapsed_time(1,1) = toc(start_time);
int_counter = 1;
counter = 1;
while (elapsed_time(counter)< sim_time)
    
    
if (counter == 1)
   time_since_last_iter = elapsed_time(1,counter)
   
else
   time_since_last_iter = elapsed_time(1,counter) -  elapsed_time(1,counter-1) 
 
end    

random_sample = poissrnd(10*time_since_last_iter,1,1);
if random_sample > 0
random_time(int_counter) = elapsed_time(counter);
int_counter = int_counter + 1;
end


disp(num2str(elapsed_time(counter)))
counter = counter+1;
elapsed_time(counter) = toc(start_time);

% % drawnow
% % hold on
% % plot(time_since_last_iter,'*r')
end


%% Test similar method used before
 for C = 1: 1000 
clear random_sample
random_sample = zeros(int32(1/time_since_last_iter),1);
for i = 1 : int32(1/time_since_last_iter)
random_sample(i) = poissrnd(10*time_since_last_iter,1,1);


end
A (C )= sum(random_sample);

 end
 
 plot(A)
 
 %% Test 3D Poisson
 ct = 1
 neurons = 10;
simNeuron = simNeurons_3D(neurons);
 while ct < 1000
 %Attachment are the Classes for generating spike train both in 2D and 3D.
%For 2D class, I have debugged it, it should works well.
%For 3D class, you can test it with the following commands:
%clear all;
neurons = 768;
% number of neurons
%simNeuron = SimBCI_3D(20,unifrnd(-2,3,[3,20])); % number and PD(3D)
vector=[1,2,3];
%pause(15)
unit_vector=vector/norm(vector);
simNeuron.generate_poisson(unit_vector,0); % direction must be an unit vector
s = simNeuron.poisson_spike;
ct  = ct +1
 end
%% plot 3D preferred directions

 [x,y,z] = sphere;
 surf(x,y,z)
 alpha(.0)

for i = 1 : neurons
starts = zeros(3,1);
ends = [simNeuron.True_PD(:,i)'];

vector = [ends(1,1) ends(1,2) ends(1,3)];
unit_vector(i) = norm(vector);
hold on
quiver3(0,0,0,ends(1,1),ends(1,2),ends(1,3))
axis equal
%
end

%plot(unit_vector)
% a = [2 3 5];
% b = [1 1 0];
% c = a+b;
% 
% starts = zeros(3,neurons);
% ends = [simNeuron.True_PD(:,1)';simNeuron.True_PD(:,2)';simNeuron.True_PD(:,3)'];
% 
% quiver3(starts(:,1), starts(:,2), starts(:,3), ends(:,1), ends(:,2), ends(:,3))
% axis equal
%% put neurons at random in a matrix of 6X128

rate = rand(1,20)

cell{5,10} = [];
for i =  1: length(r)
cell{r(i)} = rate(i)

end
a = 1;
b = 30;
r = int16((b-a).*rand(10,1) + a);


r_range = [min(r) max(r)]



index = rand

 