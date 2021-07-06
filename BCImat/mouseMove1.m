function mouseMove1 (object, eventdata)

 
C = get (gca, 'CurrentPoint');


% matrix = false(128,6);
% if (activated_channel>0 & activated_channel<=128 & activated_unit> 0 & activated_unit<= 6 )
% matrix(activated_channel,activated_unit) = 1;
% 
% I = find(matrix >0);
% correlation_tuning = object.correlation_tuning(I);
% baseline_rate = object.baseline_rate(I);
% modulation_depth = object.modulation_depth(I);
% 
% %display(num2str(C))
% title(gca, ['R = ', num2str(correlation_tuning), ', b0 = ',num2str(baseline_rate), ', MD = ',num2str(modulation_depth) ]);
%  
% C = get (gca, 'CurrentPoint');
title(gca, ['(X,Y) = (', num2str(C(1,1)), ', ',num2str(C(1,2)), ')']);
% end
end