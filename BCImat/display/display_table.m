% this function display the list of parameters in a table in a GUI,
%@ E.Ferrea, 2015
function display_table(f,position_x,position_y, length_x,length_y,decoder,calibrator)


%INPUT:

%It takes the position and length of the table, decoder and calibration objects as input.
%position_x: horizintal position of the window.
%position_y: vertical position of the window.
%length_x: window length in the horizontal dimension.
%length_y: window length in the vertical dimension.
%decoder: name of the decoder object.
%calibrator: name of the calibrator object.


[row,col] = find(decoder.neurons > 0);
index = find(decoder.neurons > 0);
data = {};
for i  = 1 : length(index)
    
    data{i,1} = ['Ch' num2str(row(i)) , 'U' num2str(col(i))];
    data{i,2} = calibrator.correlation_tuning(index(i));
    data{i,3} = calibrator. baseline_rate(index(i));
    %data{i,4} = calibrator.modulation_depth(index(i));
    data{i,4} = calibrator.training_sample_number;
end

colnames = {'neuron', 'R2', 'b0','Samples'};
t =  uitable(f,'Data', data, 'ColumnName', colnames, 'Units','normalized',...
    'Position', [position_x position_y length_x length_y]);

end