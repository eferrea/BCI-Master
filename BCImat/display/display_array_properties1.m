function display_graph(position_x,position_y, length_x,length_y,variable,flush)

line1 = 32*ones(1,6)
line2 = 64*ones(1,6)
line3 = 96*ones(1,6)
[r,c] = find(active_array~= 0);
d= uipanel('Position',[position_x position_y length_x length_y]);
s1 = subplot(4,1,1,'Parent',d);
plot(variable(array_data)

set( s1,'Position', [0.05, 0.05, 0.8, 0.85])
hold on; plot(c,r,'.r','Markersize',20)


plot([1 : 6],line1,'-r','LineWidth',1)
plot([1 : 6],line2,'-r','LineWidth',1)
plot([1 : 6],line3,'-r','LineWidth',1)


end