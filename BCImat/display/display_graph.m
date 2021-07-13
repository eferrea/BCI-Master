function display_graph(position_x,position_y, length_x,length_y,variable1,variable2,flush)

hold on
d= uipanel('Position',[position_x position_y length_x length_y]);
s1 = subplot(1,1,1,'Parent',d);
 plot(variable1,variable2,'*r')
if flush
    hold off

end