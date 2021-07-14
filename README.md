# BCImat: a Matlab Intracortical Brain Computer Interface

**Content of the package**

1. A Matlab BCI framework (BCImat).
2. A task controller written in c++ for testing BCImat (TrackM).

**Build the task controller project TrackM**

BCImat comes with a simple task controller written in c++ to interface with the BCImat. The task controller allows uers to perform sequential reacheas always starting from a central fixation circle.
The c++ project requires the graphic library SFML (available at https://www.sfml-dev.org/download.php) and the virtual reality peripheral network library (VRPN) (available at https://github.com/vrpn/vrpn/wiki) to be linked to the project. 
The project consist of a main.cpp running the task and also containing the vrpn client callback functions (similar to http://www.vrgeeks.org/vrpn/tutorial---use-vrpn) and an implemented vrpn_server class.


**Mex vrpn matlab client and server BCImat**

The BCI framework uses mexed versions of the VRPN client and server applications to exchange informations with the task controller. Therefore the vrpn_server.cpp and vrpn_client.cpp cointained in the BCI-Matlab folder need to be mexed with the vrpn library (vrpn.lib) (see mexVrpnServer.m example on how to do it on windows). 

**Description of the BCI framework**

BCImat is a Matlab GUI based program implementinhg a BCI decoder to decode movement intentions and convert them into cursor movements via two types of interfaces:
1. a simulated set of cosine tuned neurons
2. a real neural interface from Blackrock 128 channel recording system that using the cbmex.

The simulated set of units class generate spikes according to a Poisson distribution whose rate is dictated by actual mouse movement performed in a basic c++ interface.
For each neuron a random modulation depth, a baseline firing rate and a preferred direction is randomly chosen. During real movements the rate is determined by the baseline firing rate summed to  the modulation depth scaled by the angle of the actual movement direction an the preferred direction of the neuron.

At the beginning of the session the user performs reaches to the target by moving the cursor with the mouse (decoder calibration phase). When the decoder is calibrated it can be used to control cursor positions and perform the task (decoding phase). In this phase mouse movements are used to make neurons firing according to the cosine model while the decoder converts this activity into movements. 


**Running the BCI framework**

1. Start the task controller program TrackM

* specify client address (same as server address on the BCImat side)
* specify server address (same as the client address on the BCImat side)
* specify server port (here used 6666, it can be kept but if changed need to me done also on the BCImat side)
* specify dpi of your screen for pixel to mm conversion
 
2. Run the function BCI_loop.m inside BCImat with the following arguments for the simulated neural network:

* BCI_Loop(isBrain,neurons,delay,server_address,client_address) so practically will look like that

BCI_Loop(false,60,0,'TrackerBCI@172.17.6.10','TrackerTC@172.17.6.10:6666')


* and with the following arguments in case of using Blackrock hardware
BCI_Loop(true,60,0,'TrackerBCI@172.17.6.10','TrackerTC@172.17.6.10:6666')

Note that the server address corresponds to the client address on the TC control side while the opposite is true from the TC side. Additionally the server and clients addresses contain also the names of the trackers here named TrackerBCI and TrackerTC.

Also note that the client address has a specified port that has been assigned on the TC side since the same port cannot be used by two different servers with the same IP. The matlab server here uses the default port so it is not necessary to specify it. 

In case of use of a Blackrock recording system a cbmex code to stream spikes from Blackrock hardware is needed. The cbmex code is available upon installation of the Cerebus Central Suite (available at https://www.blackrockmicro.com/support/#manuals-and-software-downloads).

**Start to use the BCI**
The simplest use of the BCI requires to:
1. calibrate the decoder: perform reaches on the task controller side and then press the Update Regression button.
2. select the units used for decoding. The intensity of the color represents the tuning strength. Click to select one unit and update with the Update Regression Button.
3. After collecting enough samples (shown on the right table) press the Switch BCI button to start the decoder. In this condition, movements are guided by neurons and should follow the mouse pointer (this depends also on the quality of the calibration that is depending on number of units and number of samples). 

Additional but less relevant functionalities are listed in the next paragraph.

![BCImat](https://user-images.githubusercontent.com/40661882/125582844-48d7406e-c0f1-404a-8047-a63615ed8ab2.png)

**Matlab Graphical user interface extended functionalities**

The program make uses of callback function associated to button presses to interact with the task.
These GUI include:
1) *Check Correlation*: to check open-loop correlation among decoded and real movements.
2) *BCIIDLE*: allow to perform openloop evaluation of decoder performance. It stores internally real movements and decoded movements. Once pressiong the Check Correlation button a Pearson correlation coefficient is output for each dimension individually among decoded and real movements.
3) *Update regression*: to update calibration of the decoder.
4) *Load Decoder*: to load a previous calibrated decoder. Note that if used among different experimental sessions
the number of units should correspond as well as their tuning characteristics. Useful for now to restore previous decoders in the same session.
5) *Update Decoder*: to be used after an Updated Regression in closed-loop mode. It is meant to be used 
for retraineing calibrations in closed-loop mode. More useful for real applications than in the simulation mode.  
6) *Switch BCI*: after successful calibration to switch to close loop control.
7) *Stop BCI*: stop the program loop. Should this operation not being successfull, to restart the BCImat the vrpn server needs to be manually stopped by doing the following in the Matlab shell:  *vrpn_server('stop_server')*
8) *Reset Calibrator*: to reset the calibration if something went wrong. 
9) *Shared control*: the cursor control is shared among the computer directly pointing at the target and the neurons. Specify a number between 0-1. 1: full computer control. It is useful during subject' training phases.
11) *Perturbation panel*: rotate units preferred direction . It needs to specify the angle of rotation as well as the percentage of random units that will be rotated and start the perturbation. 
  
  Have fun!





