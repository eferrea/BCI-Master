# BCImat a Matlab Brain Computer Interface
**Description**

BCImat is a Matlab GUI based program implementinhg a BCI decoder to decode movement intetions via two types of interfaces:
1) a simulated set of cosine tuned neurons
2) a real neural interface from Blackrock 128 channel recording system that using the cbmex .

The simulated set of units class generate spikes according to a poisson distribution whose rate is dictated by actual mouse movement performed in a basic c++ human interface.
For each neuron a random modulation depth, a baseline firing rate and a preferred direction is randomly chosen. During real movements the rate is determined by the dot products of the actual movement direction 
and the preferred direction scaled by the modulation depth and summed to the baseline foring rate. 
     
The program make uses of callback function associated to button presses to interact with the task.
These GUI include:
1) Check correlation button: to check in open loop correlation among decoded and real movement signals
2) BCIIDLE: allow to perform openloop evaluation of decoder performance. It stores real movements and decoded movements. Once pressiong the check correlation button a Pearson correlation coefficient is output for each dimension individually.
3) Update regression button: to update calibration of the decoder
4) Load decoder button: to load a previous calibrated decoder. Note that if used among different experimental sessions
the number of units should correspond as well as their tuning characteristics. Useful for now to restore previous decoders in the same session.
5) Update decoder: to be used after an updated regression in closed-loop mode. It is meant to be used 
for calibrations in closed-loop mode (see Gilja et al 2012)
6) Switch BCI: after successful calibration to switch to close loop control
7) Stop BCI: stop the program loop
8) Reset calibrator: to reset the calibration if something went wrong. 
9) to reset the decoder. It should be applied if a reset calibration occurred.
10) Shared control: the control is shared among the computer directly pointing at the target and the neurons.
It is useful during subject' training phases.
11) perturbation panel: rotate units preferred direction . It needs to specify the  angle of rotation as well as the percentage of random units that will be rotated
12) After correlation button is pressed once a 
  

How to build BCImat example
BCImat comes with a c++ a simple task controller interfacing with the BCImat. allowing users to perform sequential reacheas always starting from a central fixation point.
The c++ program requires the graphic library SFML https://www.sfml-dev.org/download.php and the virtual reality peripheral network library (VRPN) https://github.com/vrpn/vrpn/wiki
