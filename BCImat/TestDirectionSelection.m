clear all


values = [0 90 180 270];
n_trials = 16;
units = 50;
for i = 1 : n_trials


r = ceil(4 + (0-4).*rand(1,1));

%values(r)
directions(i) = values(r);


end

firing_rate = rand(n_trials,units);

[C, ia, ic] = unique(directions);


[c, r] = meshgrid(1:size(firing_rate, 2), ic);

 y = (accumarray([r(:), c(:)], firing_rate(:), [], @mean));
 
 %% 
 %linearly regress every neuron and direction 
 
 theta = [0; 0; 0];
 X = [ones(length(values),1) sind(values)' cosd(values)'];
 for n = 1 : units
 
     
     Y = y(:,n)
    
%Use normal equation solution
     theta(:,n) = inv(X'*X)*X'*Y
     %Use gradient descent
     %Use matlab lenear regression function
     
 end
%Calculate baseline Firing rates as first element of theta 
 b0 = theta(1,:)';
 %Calculate modulation depth as norm of the theta matrix (without b0)
 mD = arrayfun(@(fix) norm(theta(2:end,fix)), 1:size(theta,2));
 
 pD = (theta(2:end,:)./repmat(mD,2,1));
% t1end = toc(tstart)
% tstart = tic;
% 
%      media(1,:) = mean(firing_rate(find(directions == 0),:),1);
%      media(2,:) = mean(firing_rate(find(directions == 90),:),1);
%      media(3,:) = mean(firing_rate(find(directions == 180),:),1);
%      media(4,:) = mean(firing_rate(find(directions == 270),:),1);
%      t2end = toc(tstart)

    






%% Here's a short example with a smaller matrix:

% x = [27, 10, 8;
%      28, 20, 10;
%      28, 30, 50];
% 
% We find the unique values by:
% 
% [U, ix, iu] = unique(x(:, 1));
% 
% Vector U stores the unique values, and iu indicates which index of the value associated with each row (note that in this solution we have no use for ix ). In our case we get that:
% 
% U = 
%     27
%     28
% 
% iu =
%     1
%     2
%     2
% 
% Now we apply accumarray:
% 
% [c, r] = meshgrid(1:size(x, 2), iu);
% y = accumarray([r(:), c(:)], x(:), [], @mean);
% 
% The fancy trick with meshgrid and [r(:), c(:)] produces a set of indices:
% 
% [r(:), c(:)] =
%      1     1
%      2     1
%      2     1
%      1     2
%      2     2
%      2     2
%      1     3
%      2     3
%      2     3
% 
% and these are the indices for the input values x(:), which is a column-vector equivalent of x:
% 
% x(:) =
%     27
%     28
%     28
%     10
%     20
%     30
%      8
%     10
%     50
% 
% The process of accumulation:
% 
%     The first value 27 goes to cell <1,1> in the output matrix.
%     The second value 28 goes to cell <2,1> in the output matrix.
%     The third value 28 goes to cell <2,1> in the output matrix.
% 
% See what just happened? Both values 28 get accumulated in the same cell (and eventually they will be averaged). The process continues:
% 
%     The fourth value 10 goes to cell <1,2> in the output matrix.
% 
% and so on...
% 
% Once all values are stored in cells, the function mean is applied on each cell and we get the final output matrix:
% 
% y =
%     27    10     8
%     28    25    30