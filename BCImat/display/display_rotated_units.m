function display_rotated_units(position_x,position_y, length_x,length_y,array_data,active_array,rotated_units)
% this function display rotated units in the colored unit GUI as a black cross on top of the selected unit,
%@ E.Ferrea, 2017

%INPUT 
%It takes the position and length of the table as input
%position_x: x position of the GUI in the frame
%position_y: y position of the GUI in the frame
%length_x: length of the GUI along horizontal dimension
%length_y: length of the GUI along vertical dimension
%array_data: matrix of R2 of units.
%active_array: boolean matrix of selected units

%array_data: matrix of R2 values indicating active units.
%active_array: matrix of units used for decoding.
%rotated unit: matrix of unit that are rotated

[row,col] = find(active_array ~= 0);
[row1,col1] = find(rotated_units ~= 0);
d= uipanel('Position',[position_x position_y length_x length_y]);
s1 = subplot(4,1,1,'Parent',d);
imagesc(array_data)
hold on; plot(col,row,'.r','Markersize',20)
plot(col1,row1,'xb','Markersize',10)
xlim([0.5 32.5])
s2 = subplot(4,1,2,'Parent',d);
imagesc(array_data)
hold on; plot(col,row,'.r','Markersize',20)
plot(co1,row1,'xb','Markersize',10)
xlim([32.5 64.5])
s3 = subplot(4,1,3,'Parent',d);
imagesc(array_data)
hold on; plot(col,row,'.r','Markersize',20)
plot(col1,row1,'xb','Markersize',10)
xlim([64.5 97.5])
s4 = subplot(4,1,4,'Parent',d);
imagesc(array_data)
hold on; plot(col,row,'.r','Markersize',20)
plot(col1,row1,'xb','Markersize',10)
xlim([96.5 128.5])


set(s1, 'Position', [0.05, 0.80, 0.90, 0.15])
set(s2, 'Position', [0.05, 0.55, 0.90, 0.15])
set(s3, 'Position', [0.05, 0.30, 0.90, 0.15])
set(s4, 'Position', [0.05, 0.05, 0.90, 0.15])

end