
 
 
 h = figure('Units', 'normalized', 'Color', [.9 .9 .9], 'Position', [.15 .15 .7 .6],...
    'menubar','figure','toolbar','figure');

fp3d=uipanel('Parent', h, 'Position', [.4 .32 .6 .68]);
fp2d=uipanel('Parent', h, 'Position', [.4 .001 .6 .3]);
ha3d = axes('Parent', fp3d,'Units', 'normalized','Position', [0.1 0.1 .8 .8]);
ha2d = axes('Parent', fp2d,'Units', 'normalized','Position', [0.1 0.2 .8 .7]);

set(h,'CurrentAxes',ha3d)
% axes(ha3d)

plot(rand(1,100))


set(h,'CurrentAxes',ha2d)
% axes(ha2d)
xx=0:.1:pi;
yy=sin(xx);
plot(xx,yy)
