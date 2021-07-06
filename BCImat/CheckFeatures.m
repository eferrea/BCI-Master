figure(1)
plot(obj.velocity(1,:),'r')
hold on
plot(obj.is_movement_and_hit*200,'g')
figure(2)
  X = obj.velocity(repmat(obj.is_movement_and_hit,1,3)');
                 X =    reshape(X,3,sum(obj.is_movement_and_hit))';
 plot(X(:,2))
 hold on
 plot(Z(20,:))
  %plot(10*smooth(Z(6,:),5))
 %%
  X = obj.velocity(repmat(obj.is_movement_and_hit,1,3)')
                 X =    reshape(X,3,sum(obj.is_movement_and_hit));
 Z = obj.firing_rate(repmat(obj.is_movement_and_hit,1,768));
  Z =    reshape(Z,768,sum(obj.is_movement_and_hit));
figure(3)

plot(speed)

%% plot raster
figure(4)
for i = 1 :768
    
    plot(smooth(Z(i,:),10),'.black')
    
    hold on
    
end
%plot(X(:,3))


%% normalize velocity vector position
[r,c] = size(X)
for i = 1 : r
    if all(X(i,:)) ~= 0
    X(i,:) = X(i,:)./norm(X(i,:))
    end
end

%% Test linear regression
X = X'
%Z = Z'
H = Z*X'*inv(X*X')
T = H*X;
 residuals = Z - H*X;  
                SSresiduals = sum(residuals.^2,2);
                [n_neurons,sample_number] =  size(Z);
                SStotal = (sample_number-1) * var(Z'); %check that number of samples should be greater than the number of neurons
                rsq = 1 - SSresiduals./SStotal';
                
                X_ = inv(H'*H)*H'*Z
                
                plot(1:length(X_(2,:)),X_(2,:),'r',1:length(X(2,:)),X(2,:))
                lm = X_(2,:);
                lm = smooth(X_(2,:),4)'
                rd = X(2,:);
                corr(lm',rd')
               plot(1:length(lm),lm,'r',1:length(X(2,:)),X(2,:))
                
                
                
       hold on
plot(T(104,:),'b')
plot(Z(104,:),'r')
sm = smooth(Z(104,:),5)'
lr = T(104,:); 
lr(lr<0) = 0
hold on
plot(sm,'b')
plot(lr,'r')

corr(sm',lr')
%% check firing rate

T = obj.firing_rate(repmat(obj.is_movement_and_hit,1,768));

 Z = reshape(T,sum(obj.is_movement_and_hit),768);

figure(1)
plot(obj.firing_rate(:,5),'r')
hold on
plot(obj.is_movement_and_hit*30,'g')
figure(2)
  plot(Z(:,5))