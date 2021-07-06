function PlotUpdateTimeCompare(f,x,y,trial_counter) 


%fp3d=uipanel('Parent', f, 'Position', [.4 .32 .6 .68]);
fp2d=uipanel('Parent', f, 'Position', [.4 .001 .6 .3]);
%ha3d = axes('Parent', fp3d,'Units', 'normalized','Position', [0.1 0.1 .8 .8]);
ha2d = axes('Parent', fp2d,'Units', 'normalized','Position', [0.1 0.2 .8 .7]);

%set(f,'CurrentAxes',ha2d)
% axes(ha3d)

hold on
 plot(x,y,'r','Markersize',0.5);

set(f,'CurrentAxes',ha2d)
hold on
% if trial_counter == 2
%     hold off
%      plot(x,y,'r','Markersize',0.5);
% end
%   hold on
%      plot(x,y,'r','Markersize',0.5);
%       
%set(fp2d,'XData',x,'YData',y);
     pause(0.002)
end