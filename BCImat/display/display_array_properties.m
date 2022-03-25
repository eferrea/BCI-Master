function display_array_properties(position_x,position_y, length_x,length_y,array_data,active_array)
%% this function display array layout,
%@ E.Ferrea, 2015

%INPUT:

%position_x: horizontal position of the GUI in the frame.
%position_y: vertical position of the GUI in the frame.
%length_x: length of the GUI along horizontal dimension.
%length_y: length of the GUI along vertical dimension.
%array_data: matrix of R2 of units.
%active_array: boolean matrix of selected units.

[r,c] = find(active_array~= 0);
d= uipanel('Position',[position_x position_y length_x length_y]);
%d.Title = 'Intracortical arrays - Click on colored unit and push calibration button ';
s1 = subplot(4,1,1,'Parent',d);
imagesc(array_data)
hold on; plot(c,r,'.r','Markersize',20)
xlim([0.5 32.5])
s2 = subplot(4,1,2,'Parent',d);
imagesc(array_data)
hold on; plot(c,r,'.r','Markersize',20)
xlim([32.5 64.5])
s3 = subplot(4,1,3,'Parent',d);
imagesc(array_data)
hold on; plot(c,r,'.r','Markersize',20)
xlim([64.5 97.5])
s4 = subplot(4,1,4,'Parent',d);
imagesc(array_data)
hold on; plot(c,r,'.r','Markersize',20)
xlim([96.5 128.5])


set(s1, 'Position', [0.05, 0.80, 0.90, 0.15])
set(s2, 'Position', [0.05, 0.55, 0.90, 0.15])
set(s3, 'Position', [0.05, 0.30, 0.90, 0.15])
set(s4, 'Position', [0.05, 0.05, 0.90, 0.15])

end