# BCImat:  a Matlab-based framework for Intracortical Brain-Computer Interfaces and their simulation with an artificial spiking neural network


**Content of the package**

1. A Matlab BCI framework (BCImat).
2. A Visual Studio project implementing a task controller written in c++ for testing the Matlab BCI framework  (TrackM).

**Purpose of the BCI framework (BCIMat)**

BCImat is a Matlab GUI based program implementinhg a Brain-Computer Interface (BCI) decoder interpreting movement intentions from intracortical neural activity and converting them into cursor movements. Neural activity is provided via two types of interface:
1. a simulated set of cosine tuned neurons for testing purposes prior to real brain control (simulation mode),
2. a real neural interface using Blackrock 128 channel recording system (Blackrock Microsystems, Salt Lake City, USA, https://www.blackrockmicro.com/) via their cbmex code for real intracortical control (application mode).

**Purpose of the task controller (TrackM)**

TrackM is an example software written in C++ implementing a standard task controller for a reaching task with the mouse pointer to displayed targets. This part of the software can be replaced (or expanded) depending on which behavioral task one wants to be performed. Therefore, despite this not being the core of the project, users can test the full BCI closed-loop functionalities by running the task controller simultaneously with the BCI matlab framework. This part of the project can also be written in any other programming language as far as the vrpn methods are used to send and read the data to and from the BCImat interface. TrackM contains a main.cpp together with a class implementation of the vrpn server method which should be build with VRPN (for streaming the data via network) and SFML libraries (for graphical displays of targets to be reached). 

**Build the task controller project TrackM**

BCImat comes with a simple task controller written in c++ to interface with the BCImat. The task controller allows users to perform sequential reacheas to  a target (green circle) starting from a central fixation circle (gray).
The c++ project requires the graphic library SFML (available at https://www.sfml-dev.org/download.php) and the virtual reality peripheral network library (VRPN) (available at https://github.com/vrpn/vrpn/wiki) to be linked to the project. 
The project contains a main.cpp running the task including the vrpn client callback functions (similar to http://www.vrgeeks.org/vrpn/tutorial---use-vrpn) as well as an implemented vrpn server class. These files are contained in the "Source Files" folder of the project and can be also used to make a project from scratch in other integrated development environment (we also tested Xcode). 


**VRPN matlab client and server for BCImat**

The BCImat framework is a Matlab program that uses Matlab executable (mex) versions of the VRPN client and server applications to exchange information with the task controller. Here, we provide precompiled versions of the vrpn_server.cpp and  vrpn_client.cpp for 64 bit Matlab both in Mac and Windows. If they do not work, the vrpn_server.cpp and vrpn_client.cpp cointained in ./BCI-mat/mex folder need to be mexed with the vrpn library (vrpn.lib) (see mexVrpnServerAndClient.m example on how to do it on Windows and Mac). Please note that for a 64 bit Matlab version a 64 bit version of vrpn.lib needs to be built. Please also note that in Windows for successsfully producing the Matlab executable of the vrpn server and client, the vrpn.lib needs to me build with the Runtime library Multi-threaded DLL (/MD).

Here, vrpn version 7.33 in Windows and Mac was tested. 


**Running the BCI framework**

1. Edit the provided configuration file by entering a name for the Tracker (mouse pointer in this case) implemented in the task controller (trackM) followed by @*<server_address>*. Also a name for the Tracker (output of the BCI decoder) implemented in the BCI server is needed and followed by @<client_address>. Here TrackerTC and TrackerBCI are used as names followed by their IP adresses. They specify the adresses of the computers were the task controller and the BCImat framework run.  
Note that the task controller streams the information of the mouse pointer (*TrackerTC*) by implementing a vrpn server to the BCI framework and read the information provided by the BCI framework (via *TrackerBCI*) by implementing a vrpn client.
Also a name of a port needs to be added to avoid conflictts when task controller and BCI framework run on the same computer. The provided entry <6666> can be left unchanged.
Also the number of dots per inch for the specific used screen should be specified for pixel to mm conversions (not critical)
In summary the configuration file should look like that:

IP_address_server = TrackerTC@127.0.0.1  
IP_address_client = TrackerBCI@127.0.0.1   
port = 6666  
dpi = 108.79 


2. Run the task controller program TrackM
 
3. Run the function BCI_loop.m inside BCImat with the following arguments:

* for the simulation mode:
BCI_Loop(isBrain,neurons,BCI_update_time,delay,server_address,client_address,port)

practically it will look like that:

BCI_Loop(false,60,0.05,0,'TrackerBCI@172.17.6.10','TrackerTC@172.17.6.10',6666)

The simulated set of unit spikes are generated in a Matlab class according to a Poisson distribution the rate of which is dictated by actual mouse movement performed in the c++ task interface.
For each neuron a random modulation depth, a baseline firing rate and a preferred direction is randomly chosen. During real movements the rate is determined by the baseline firing rate summed to  the modulation depth scaled by the angle of the actual movement direction an the preferred direction of the neuron.


* and with the following arguments in case of application mode:
BCI_Loop(true,60,0.05,0,'TrackerBCI@127.0.0.1','TrackerBCI@127.0.0.1:6666')


Note that the server address corresponds to the client address on the  task controller side while the opposite is true from the task controller side. Additionally, the server and clients addresses contain the names of the trackers that are named in the example TrackerBCI and TrackerTC preceeding the IP addresses.

Also note that the client address has a specified port that has been assigned on the task controller side since the same port cannot be used by two different servers with the same IP. Here, the matlab server uses the default port so it is not necessary to specify it independently. 

In case of use of a Blackrock recording system the cbmex code streaming spikes from Blackrock hardware is needed. The cbmex code is available upon installation of the Cerebus Central Suite (available at https://www.blackrockmicro.com/support/#manuals-and-software-downloads).


**Start to use the BCI**

At the beginning of the session the user performs reaches to the target by moving the cursor with the mouse (decoder calibration phase). Once the decoder is calibrated, it can be used to control cursor positions and perform the task (decoding phase). In this phase and in the simulation mode, mouse movements are used to make neurons firing according to the cosine model while the decoder converts this activity into movements. 

Therefore, the simplest use of the BCI requires to:
1. calibrate the decoder: perform reaches on the task controller side and then press the Update Regression button.
2. select the units used for decoding. The intensity of the color represents the tuning strength. Click to select one unit and update with the Update Regression button.
3. After collecting enough samples (samples are shown on the right table) press the Switch BCI button to start the decoder. In this condition, movements are guided by neurons and should follow the mouse pointer in the simulation mode (this depends also on the quality of the calibration that is depending on number of units and number of samples). 

Additional functionalities are listed in the next paragraph.


![layoutBCI](https://user-images.githubusercontent.com/40661882/145232704-86035c3a-d15d-4000-82b9-643736b52dd1.jpg)


*Fig 1.	Graphical user interface exploiting BCI functionalities. The GUI layout on the left displays all possible recorded units arranged to reflect our experimental settings. Since we recorded simultaneously from four electrode arrays each of them containing 32 channels (total 128 of recording sites), we clearly separate each array from the other in the visualization. The identity of the channel is arranged as column while each row represents a different unit (or spike) for that channel. For each electrode array, we split the data in six rows given that the recording system streams a maximum of six units (after online sorting). In the middle column the name of the selectcted unit is displayed (ch = channel identity, U = unit identity)* together with the its tuning properties calculated after the specific calibration intervals (Samples) of the decoder. R2 represents the explained variance of fitting a cosine tuned model to the firing rate of each single cell. This value is also color coding the GUI on the left column. For this reason strongly tuned cells are identified with warmer columns.  


**Matlab Graphical user interface extended functionalities**

The program make uses of callback function associated to button presses to interact with the task.
These GUIs include:
1) *Check Correlation*: to check open-loop correlation among decoded and real movements.
2) *BCIIDLE*:  to perform openloop evaluation of decoder performance. It stores internally real movements and decoded movements. By pressing the Check Correlation button a Pearson correlation coefficient is output for each dimension individually among decoded and real movements.
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





