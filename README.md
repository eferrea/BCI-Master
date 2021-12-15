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

The BCImat framework is a Matlab program that uses Matlab executable (mex) versions of the VRPN client and server applications to exchange information with the task controller. Here, we provide precompiled versions of the vrpn_server.cpp and  vrpn_client.cpp for 64 bit Matlab both in Mac and Windows. If they do not work, the vrpn_server.cpp and vrpn_client.cpp cointained in ./BCI-mat/mex folder need to be mexed with the vrpn library (vrpn.lib) (see mexVrpnServerAndClient.m example on how to do it on Windows and Mac). Please note that for a 64 bit Matlab version a 64 bit version of vrpn.lib needs to be built. Please also note that in Windows for successsfully obtaining the Matlab executable of the vrpn server and client, the vrpn.lib needs to be build with the Runtime library Multi-threaded DLL (/MD).

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
BCI_Loop(true,60,0.05,0,'TrackerBCI@127.0.0.1','TrackerBCI@127.0.0.1',6666)


Note that the server address corresponds to the client address on the  task controller side while the opposite is true from the task controller side. Additionally, the server and clients addresses contain the names of the trackers that are named in the example TrackerBCI and TrackerTC preceeding the IP addresses.

Also note that the client address has a specified port that has been assigned on the task controller side since the same port cannot be used by two different servers with the same IP. Here, the matlab server uses the default port so it is not necessary to specify it independently. 

In case of use of a Blackrock recording system the cbmex code streaming spikes from Blackrock hardware is needed. The cbmex code is available upon installation of the Cerebus Central Suite (available at https://www.blackrockmicro.com/support/#manuals-and-software-downloads).


**Test procedure**

The user should performs reaches to the visual targets in the TrackM program by moving the cursor with the mouse (decoder calibration phase). Once the decoder is calibrated, it can be used to control cursor positions and perform the task (decoding phase). In this phase and in the simulation mode, mouse movements are used to elicit neuronal responses according to each neuron preferred direction while the decoder converts this activity into movements. The task is a center out reach task so movements are required to always start at the center of the workspace. This means that to start reaches to a new target, the user should point the mouse to the gray target at the centre of the workspace. In this way at the beginning of the reach, the mouse pointer and the cursor are maximally aligned.    

Therefore, the simplest use of the BCI requires to:
1. Perform several (e.g.10) reaches to the targets. 
2. Press the Update Regression button to open the single unit GUI.The intensity of the color represents the tuning strength.
3. Select several units for decoding (e.g.30-40 for good performance) by clicking on the colored square of the GUI and update with the Update Regression button to update visualization.
4. After collecting enough samples (samples are shown on the right table, 150-200 for good performance) press the Switch BCI button to start the decoder. In this condition, movements are controlled by neurons and should follow the mouse pointer in the simulation mode (this depends also on the quality of the calibration that is depending on number of units and number of samples).
5 After a successfull target acquisition, the mouse pointer should be positioned at the gray target to start a new reach.





![layoutBCI](https://user-images.githubusercontent.com/40661882/145967910-9d38d0a2-9b4b-426e-9fd3-167733019df8.jpg)



*Fig 1.	Graphical user interface exploiting BCI functionalities. The GUI layout on the left displays all recorded units arranged in a way reflecting our experimental settings. Since we recorded simultaneously from four electrode-arrays each of them containing 32 channels (total of 128 recording sites), we separate each array from the other in the visualization. The identity of the channel is arranged as column while each row represents a different unit (a spike) for that channel. For each electrode array, we split the data in six rows given that the recording system streams a maximum of six units (after online sorting). In the middle column, the name of the selectcted unit is displayed (ch = channel identity, U = unit identity)* together with the its tuning properties calculated after the specific calibration intervals (Samples) of the decoder. R2 represents the explained variance of fitting a *cosine tuning* model to the firing rate of each single cell. This value is also color coding the GUI on the left column. For this reason, strongly tuned cells are identified with warmer columns. The value under *bo* represents the estimated baseline firing rate of each cell while *Samples* represents the valid number of samples that were acquired (one every BCI_update_time for valid trials). The functionalities of the buttons on the right column and at the bottom left are extensively explained in the *Matlab Graphical user interface extended functionalities* paragraph and determine the behavior of the BCI.   


**Matlab Graphical user interface functionalities**

The program make uses of callback function associated to button presses to interact with the task.
These GUIs include:

1) Single Unit GUI (left column): click on single units to select them to be part of the decoder. This panel is first displayed after pressing the Update Regression button for the first time. Selecting units with warmer color (higher R2) provides better decoding performance.
2)  *Update Regression*: to update calibration of the decoder after performing movements. This button should be pressed everytime a substantial amount of samples is performed.It can be used during calibration to control which units give a better tuning (higher R2) or during BCI online mode to improve the calibration. The online mode calibration assume that the movement is always pointing to the target. (Gjlia et al 2012).Internally calibrations done with real movements and during closed loop are kept separated so it is possible to retrieve data automatically when switching from one modality of calibration to another.  
3) *BCIIDLE*:  to evaluate decoder performance without closing the BCI loop (open loop). It stores internally real speeds and decoded speeds. 
4) *Check Correlation*: to be used in BCIIDLE mode, by pressing this button the Pearson correlation coefficient is estimated among decoded speeds and real speeds. This button is mainly intended for the application mode where prior allowing users to control the decoder a decent (offline) performance needs to be achieved.
5) *Switch BCI*: after successful calibration to switch to close loop control. It switch to the BCI closed-loop mode. A decent amount of units (30-40) and a decent amount of samples (200-300) needs to be acuired to achieve a decent performance (in offline mode the green cursor should be reliably controlled with the mouse pointer).
6) *Update Decoder*: to be used after a recalibration in closed-loop mode with Updated Regression. Important for real applications not in the simulation mode.  
6) *Load Decoder*: to load a previous calibrated decoder. Note that if used among different experimental sessions
the number of units should correspond as well as their tuning characteristics. Useful for now to restore previous decoders in the same session but potentially useful to use the same decoder across many days.
7) *Stop BCI*: stop the program loop. Should this operation not being successfull, to restart the BCImat the vrpn server needs to be manually stopped by doing the following in the Matlab shell:  *vrpn_server('stop_server')*
8) *Reset Calibrator*: to reset the calibration if something went wrong during calibration. It starts to recollect speed and neural samples.  
9) *Shared control*: the cursor control is shared among the computer directly pointing at the target and the neurons. Specify a number between 0-1. 1: full computer control. It is useful during subject' training phases and to recalibrate the decoder during closed loop control. The idea is that during real experiments a high level of computer control is introduced to maintain high performance. During the task as subject acquire proficiency with the control the amount of control from the computer side is reduced.
11) *Perturbation panel*: rotate units preferred direction . It needs to specify the angle of rotation as well as the percentage of random units that will be rotated and start the perturbation. By rotating the preferred direction of some units during closed-loop control, the direction of movement deviates from the intended movement directions. This panel is intended to introduce visuo-motor rotations of the cursors useful for motor learning studies.

**Detailed explanation of other contents of the package**
1) simNeurons_2D_velocity.m class that is used inside BCI_loop.m to generate firing rates of artificial neurons according to a Poisson distribution. During each small  movement (e.g 50 ms timestamp), the mean of each poisson neuron is determined by the baseline firing rate plus the cosine of the actual moving direction and the neuron prefered direction moltiplied by the modulation depth. Each neuron preferred direction is determined according to a circular uniform distribution.  This class also uses an hard coded modulation depth in the physiological range of 4-18 Hz and a baseline firing rates in the range 4-20.  Future realease of this classes could include the possibility of specifying these ranges. 

2) task_parser.m: this simple class is used to handle messages coming from the task controller. It is important for the BCImat to know information about the state of the task to adapt its behaviour accordingly. For example it could be useful to collect samples of firing rates and positional samples only when the users are engaged with the motor task. In this case we decided to store the values for calibration online during the last stage of the task (stage 3). 

3) Kalman  

  
  Have fun!





