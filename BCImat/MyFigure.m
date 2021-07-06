fh = figure('Position',[1000 600 700 500])
%Configure sopt window
h = uicontrol('Style', 'PushButton', 'String', 'Stop BCI', ...
    'Callback', 'delete(gcbo)','Position',[400 100 200 100]);

g = uicontrol('Style', 'PushButton', 'String', 'Switch BCI', ...
    'Callback',@myfunc,'Position',[400 200 200 100]);

%fh


subplot(4,1,1)
image(img1)
subplot(4,1,2)
image(img1)
subplot(4,1,3)
image(img1)
subplot(4,1,4)
image(img1)

set(subplot(4,1,1), 'Position', [0.05, 0.75, 0.42, 0.1])
set(subplot(4,1,2), 'Position', [0.05, 0.55, 0.42, 0.1])
set(subplot(4,1,3), 'Position', [0.05, 0.35, 0.42, 0.1])
set(subplot(4,1,4), 'Position', [0.05, 0.15, 0.42, 0.1])

%C = get (gca, 'CurrentPoint');
%set (gcf, 'WindowButtonMotionFcn', @mouseMove);
 set (gcf, 'WindowButtonDownFcn', {@mouseClick,)
 get(gcf,'WindowButtonDownFcn')
 %get(gcf,'WindowButtonDownFcn')
 get (gcf)
 f = figure('Position',[300 300 300 200]);
p = uipanel('Position',[.2 .2 .6 .6]);
h1 = uicontrol(p,'Style','PushButton',...
               'Units','normalized',...
               'String','Push Button',...
               'Position',[.1 .1 .5 .2]);

% h = imshow('pout.tif');
% [nrows,ncols] = size(get(h,'CData'));
% xdata = get(h,'XData')
% ydata = get(h,'YData')
% px = axes2pix(ncols,xdata,30)
% py = axes2pix(nrows,ydata,30)
% 
% xdata = [10 100]
% ydata = [20 90]
% px = axes2pix(ncols,xdata,30)
% py = axes2pix(nrows,ydata,30)