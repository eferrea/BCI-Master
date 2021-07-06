a = false(10,10)

b = true(10,10)


fh = figure('Position',[900 200 1000 900])
set (gcf, 'WindowButtonMotionFcn',@mouseMove1);
%Panel to put the switch and close BCI buttons
p = uipanel('Position',[0.1 0.1 .4 .4]);

s1 = subplot(1,1,1,'Parent',p);
imagesc(a)


d = uipanel('Position',[0.5 0.1 .4 .4]);
%set (gcf, 'WindowButtonMotionFcn',@mouseMove1);
s2 = subplot(1,1,1,'Parent',d);
imagesc(b)
