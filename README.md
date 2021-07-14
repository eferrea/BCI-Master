# BCImat a Matlab Brain Computer Interface

**Content of the package*

1. A Matlab BCI framework (BCImat).
2. A task controller written in c++ for testing BCImat (TrackM).

**Build the task controller project TrackM**

BCImat comes with a simple task controller writte in c++ to interface with the BCImat. The task controller allows uers to perform sequential reacheas always starting from a central fixation circle.
The c++ project requires the graphic library SFML (available at https://www.sfml-dev.org/download.php) and the virtual reality peripheral network library (VRPN) (available at https://github.com/vrpn/vrpn/wiki) to be linked to the project. 
The project consist of a main.cpp running the task and also containing the vrpn client callback functions (similar to http://www.vrgeeks.org/vrpn/tutorial---use-vrpn) and an implemented vrpn_server class.


**Mex vrpn matlab client and server BCImat**

The BCI framework used mexed versions of the VRPN client and server applications. Therefore the vrpn_server.cpp and vrpn_client-cpp cointained in the BCI-Matlab folder need to be mexed with the vrpn library (see mex_vrpn_example.mat on how to do it in mac and windows). 

**Description**

BCImat is a Matlab GUI based program implementinhg a BCI decoder to decode movement intentions and convert them into cursor movements via two types of interfaces:
1. a simulated set of cosine tuned neurons
2. a real neural interface from Blackrock 128 channel recording system that using the cbmex.

The simulated set of units class generate spikes according to a Poisson distribution whose rate is dictated by actual mouse movement performed in a basic c++ interface.
For each neuron a random modulation depth, a baseline firing rate and a preferred direction is randomly chosen. During real movements the rate is determined by the baseline firing rate summed to  the modulation depth scaled by the angle of the actual movement direction an the preferred direction of the neuron.



**Running the BCI framework**

1. Start the task controller program

* specify client address (same as server address on the BCImat side)
* specify server address (same as the client address on the BCImat side)
* specify server port (here used 6666, it can be kept but if changed need to me done also on the BCImat side)
* specify dpi of your screen for pixel to mm conversion
 
2. Run the function BCI_loop.m with the following arguments for the simulated neural network:

* BCI_Loop(isBrain,neurons,delay,server_address,client_address) so practically will look like that

BCI_Loop(false,60,0,'TrackerBCI@172.17.6.10','TrackerTC@172.17.6.10:6666')



* and with the following arguments in case of using Blackrock hardware
BCI_Loop(true,60,0,'TrackerBCI@172.17.6.10','TrackerTC@172.17.6.10:6666')

Note that the server_address correspondsto the client server address on the TC control side whreaslient address to the server address on the TC side. Additionally the server and clients addresses contain also the names of the trackers.

Also note that the client address has a specified port that has been assigned on the TC side since the same port cannot be used by two different server with the same IP. The matlab server here uses the default port so it is not necessary to specify it. 

In case of use of a Blackrock recording system a cbmex code to stream spikes from Blackrock hardware is needed. The cbmex code is available upon installation of the Cerebus Central Suite (available at https://www.blackrockmicro.com/support/#manuals-and-software-downloads).

**Start to use the BCI**
The simplest use of the BCI requires to:
1. calibrate the decoder: perform reaches on the task controller and then press the Update regression button.
2. select the units in used for decoding. The intensity of the color represents the tuning strength.
3. After collecting enough samples (shown on the right table) press the start BCI buttonto start the decoder. In this condition mouse movements are used to make the neuron firing according to the direction of movements. Movements are guided by neurons but should follow the mouse pointer (this depends on the quality of the calibration that is number of units and number of samples). Additional but less relevant functionalities are listed in the next paragraph.

![BCImat](https://user-images.githubusercontent.com/40661882/125582844-48d7406e-c0f1-404a-8047-a63615ed8ab2.png)

**Matlab Graphical user interface extended functionalities**

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
  





