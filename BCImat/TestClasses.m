%Test class stuff
clear all
cal = calibrator_class();
bci = decoder_class(128, 2,now,0.03);

cal.update_decoder(bci)

bci.pD
bci.mD
bci.b0