%% Initialize text file to store values
[year,month,day] =  ymd(datetime);
[hour,minute,second] = hms(datetime);
filename_root = [num2str(year) '-' num2str(month) '-' num2str(day) '_' num2str(hour) '-'  num2str(minute) '-'  num2str(int8(second))];

filename_decoder = [filename_root '_decoder.txt']

fileID_decoder = fopen(filename_decoder,'at');
% printfFormatTrackHeader = ['%6s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s %12s\n'];
printfFormatDecoderBody = ['%12.3f %25.3f %12.3f\n'];
% fprintf(fileID_track,printfFormatTrackHeader,'time','pos_x','pos_y','pos_z','vel_x','vel_y','vel_z',...
%     'BCI_pos_x','BCI_pos_y','BCI_pos_z','BCI_vel_x','BCI_vel_y','BCI_vel_z');
%header of task controller file
%fprintf(fileID_task,'%6s %12s %25s %12s %12s %12s %12s %12s %12s %12s\n','time','Trial','Stage','BCI_on', 'IDLE_on', 'tgt_x','tgt_y','tgt_z','Hit', 'EYE_on');
printfFormatDecoderHeader = ['%6s' '%6s\n'];

fprintf(fileID_decoder,printfFormatDecoderHeader,'time','K');
fprintf(fileID_decoder,printfFormatDecoderBody,1,2,3);