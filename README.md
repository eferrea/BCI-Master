# BCImat:  a Matlab-based framework for Intracortical Brain-Computer Interfaces and their simulation with an artificial spiking neural network


## **Content of the package**

This package contains two main components:

1. A Matlab BCI framework (BCImat).
2. A c++ project (TrackM) implementing a task controller for testing the Matlab BCI framework in a closed-loop fashion.

## **Purpose of the BCI framework (BCIMat)**

BCImat is a Graphical User Interface (GUI)-based program developed in Matlab. It serves as a Brain-Computer Interface (BCI) framework designed to interpret movement intentions from intracortical neural activity and translate them into cursor movements. BCImat supports two primary modes of operation:
1. **Simulation mode**
   * BCImat provides a simulated set of cosine-tuned neurons, as described by Georgopoulos et al. in 1982. This mode is intended for testing purposes to ensure the functionality of the BCI framework before using it under real brain control.
2. **Application mode**
   * In application mode, BCImat interfaces with real neural data obtained from a Blackrock 128-channel recording system (manufactured by Blackrock Microsystems, Salt Lake City, USA). This connection is established using the cbmex code, enabling real intracortical control.
   
**Dependencies**
* The current version of BCImat requires the "Statistics and Machine Learning Toolbox." However, in future releases, efforts will be made to eliminate dependencies on this toolbox.
**Compatibility**
* BCImat was primarily developed and tested using Matlab 2016a with the Statistics and Machine Learning Toolbox version 10.2. It has also been successfully tested with Matlab version 2018b and the Statistics and Machine Learning Toolbox version 11.4.

## **Purpose of the task controller (TrackM)**

TrackM is a sample software application written in C++, serving as a standard task controller designed for a reaching task. This task controller enables users to perform sequential reaches to a target represented as a green circle, starting from a central fixation circle in gray. While this component isn't the primary focus of the project, it plays a crucial role in enabling users to test the full Brain-Computer Interface (BCI) closed-loop functionalities in conjunction with the BCI Matlab framework. 
TrackM's interface is not limited to C++; it can be implemented in any programming language that utilizes Virtual-Reality Peripheral Network (VRPN) methods to send and receive data with the BCImat interface. This interoperability opens up possibilities for diverse development environments while ensuring seamless communication with the BCImat framework.

**Components**

TrackM consists of the following components:

* main.cpp: The main program file responsible for orchestrating the task controller's functionality.
* vrpn_server_class: A class implementation used to establish a VRPN server method. This method facilitates * data streaming via network communication.
Dependencies: TrackM relies on external libraries, including VRPN (for data streaming) and SFML (for graphical displays of target objects).

## Build the Task Controller Project TrackM

The **TrackM** folder contains the source code and a `CMakeLists.txt` file to build the project on different OS architectures. To successfully build **TrackM**, you'll need to have the following libraries installed on your computer:

1. **SFML** (Simple and Fast Multimedia Library) - [Download SFML](https://www.sfml-dev.org/download.php)
2. **VRPN** (Virtual Reality Peripheral Network) - [VRPN GitHub Repository](https://github.com/vrpn/vrpn)

## Installation Prerequisites

Before proceeding, make sure you have SFML and VRPN installed. After installing these libraries, follow the steps below to generate the build environment using CMake:

### Windows

On Windows, you will need to specify the paths to the include and library folders of SFML and VRPN in the `CMakeLists.txt` file. To do this, locate the following lines in the `CMakeLists.txt` file and replace the placeholders with the full paths to your libraries:

SET(SFML_INCLUDE_PATH <change to the full path of your SFML include directory>)
SET(VRPN_INCLUDE_PATH <change to the full path of your VRPN include directory>)
SET(SFML_LIBRARY_PATH <change to the full path of your SFML lib directory>)
SET(VRPN_LIBRARY_PATH <change to the full path containing vrpn.lib>)
SET(VRPN_QUAT_LIBRARY_PATH <change to the full path containing quat.lib>)
SET(SFML_DLL_PATH <change to SFML folder containing DLLs, they should be in sfml-install-path/bin>)

### Linux
On Linux, you generally don't need to specify custom library paths unless you've installed the libraries in non-standard locations.

### macOS
macOS was not extensively tested, but the CMakeLists.txt file contains specific instructions for it. If you encounter issues, you may need to specify the include and library folders for SFML and VRPN on macOS.

### Library Versions
Please note that the testing was performed with VRPN version 7.33 and SFML version 2.5.1. Ensure that you have these specific versions installed for compatibility.

These instructions should help you set up and build the TrackM project. If you have any questions or encounter issues, refer to the respective library's documentation for installation guidance.

**VRPN Matlab client and server for BCImat**

The BCImat framework is a Matlab program that uses Matlab executable (mex) versions of the VRPN client and server applications to exchange information with the task controller. Here, we provide precompiled versions of the vrpn_server.cpp and vrpn_client.cpp for 64 bit Matlab both in Mac and Windows. If they do not work, the vrpn_server.cpp and vrpn_client.cpp contained in ./BCI-mat/mex folder need to be mexed with the VRPN library (vrpn.lib) (see mexVrpnServerAndClient.m example on how to do it on Windows and Mac). Please note that for a 64 bit Matlab version a 64 bit version of vrpn.lib needs to be built. Please also note that in Windows for successfully obtaining the Matlab executable of the VRPN server and client, the vrpn.lib needs to be built with the Runtime library Multi-threaded DLL (/MD).



**Running the full BCI loop (TrackM + BCImat)**

1. Edit the provided configuration file by entering a name for the Tracker (mouse pointer in this case) implemented in the task controller (TrackM) followed by @*<server_address>*. Also, a name for the Tracker (output of the BCI decoder) implemented in the BCI server is needed and followed by @<client_address>. Here TrackerTC and TrackerBCI are used as names followed by their IP addresses. They specify the addresses of the computers where the task controller and the BCImat framework run.  
Note that the task controller streams the information of the mouse pointer (*TrackerTC*) by implementing a VRPN server to the BCI framework and reads the information provided by the BCI framework (via *TrackerBCI*) by implementing a VRPN client to update the position of the controlled cursor.
A name of a port needs to be added to avoid conflicts when the task controller and BCI framework run on the same computer. The provided entry <6666> can be left unchanged.
Also, the number of dots per inch for the specific screen resolution should be specified for pixel to mm conversions (not critical)
In summary, the configuration file should look like that (when TrackM and BCImat run on the same computer):

IP_address_server = TrackerTC@127.0.0.1  
IP_address_client = TrackerBCI@127.0.0.1   
port = 6666  
dpi = 108.79 


2. Run the task controller program TrackM.
 
3. Run the function BCI_loop.m inside BCImat with the following arguments (add also subfolders of BCImat to Matlab path):

* for the simulation mode:
BCI_Loop(isBrain,neurons,BCI_update_time,delay,server_address,client_address,port)

practically it will look like that:

BCI_Loop(false,60,0.05,0,'TrackerBCI@172.17.6.10','TrackerTC@172.17.6.10',6666)

The simulated set of spikes is generated in a Matlab class according to a Poisson distribution the rate of which is dictated by actual mouse movement performed in the c++ task interface.
For each neuron, a random modulation depth, a baseline firing rate, and a preferred direction are randomly chosen. During real movements, the rate is determined by the baseline firing rate summed to the modulation depth scaled by the cosine of the angle between the actual movement direction and the preferred direction of the neuron.


* and with the following arguments in case of application mode:
BCI_Loop(true,60,0.05,0,'TrackerBCI@127.0.0.1','TrackerTC@127.0.0.1',6666)


Note that the server address corresponds to the client address on the task controller side while the opposite is true from the task controller side. Additionally, the server and client addresses contain the names of the trackers that are named in the example TrackerBCI and TrackerTC preceding the IP addresses.

Also, note that the client address has a specified port that should be assigned on the task controller side since the same port cannot be used by two different servers with the same IP. Here, the Matlab server uses the default port so it is not necessary to specify it independently. 

In the case of use of a Blackrock recording system, the cbmex code streaming spikes from Blackrock hardware is needed. The cbmex code is available upon installation of the Cerebus Central Suite (available at https://www.blackrockmicro.com/support/#manuals-and-software-downloads).


**Test procedure (simulation mode)**

The user should reach the visual targets in the TrackM program by moving the cursor with the mouse for the decoder calibration phase. Once the decoder is calibrated, it can be used to control cursor positions and perform the task (decoding phase). In this phase, mouse movements are used to trigger neuronal responses according to their preferred directions while the decoder converts this activity into movements. The task is a center-out reach task so movements are required to always start at the center of the workspace. This means that to start reaches to a new target, the user should point the mouse to the gray target at the center of the workspace. In this way at the beginning of the reach, the mouse pointer and the cursor are maximally co-localized.    

Therefore, the simplest use of the BCI requires to:
1. Perform several (e.g.10) reaches to the targets. 
2. Press the Update Regression button to open the single unit GUI. The intensity of the color represents the tuning strength.
3. Select several units for decoding (e.g.30-40 for good performance) by clicking on the colored square of the GUI and updating with the Update Regression button to update visualization.
4.  After collecting enough samples by continuously reaching the target and updating by pressing the Update Regression Button (samples are shown on the right table, 150-200 for good performance), press the Switch BCI button to start the decoder. In this condition, movements are controlled by neurons and should follow the mouse pointer in the simulation mode (this depends also on the quality of the calibration that is depending on the number of units and number of samples).
5. To successfully acquire a target, move the mouse pointer inside the gray target to start a new reach. At this point, a green cursor will appear. Try to move the green cursor to the target by adjusting it with mouse movements.  





![layoutBCI](https://user-images.githubusercontent.com/40661882/145967910-9d38d0a2-9b4b-426e-9fd3-167733019df8.jpg)



*Fig 1.	Graphical user interface exploiting BCI functionalities. The GUI layout on the left displays all recorded units arranged in a way reflecting our experimental settings. Since we recorded simultaneously from four electrode arrays each of them containing 32 channels (total of 128 recording sites), we separate each array from the other in the visualization. The identity of the channel is arranged in columns while each row represents a different unit (a spike) for that channel. For each electrode array, we split the data into six rows given that the recording system streams a maximum of six units (after online sorting). In the middle column, the name of the selected unit is displayed (ch = channel identity, U = unit identity)* together with its tuning properties calculated after the specific calibration intervals (Samples) of the decoder. R2 represents the explained variance of fitting a *cosine tuning* model to the firing rate of every single cell. This value is also color-coding the GUI on the left column. For this reason, strongly tuned cells are identified with warmer columns. The value under *bo* represents the estimated baseline firing rate of each cell while *Samples* represents the valid number of samples that were acquired (one every BCI_update_time for valid trials). The functionalities of the buttons on the right column and at the bottom left are extensively explained in the *Matlab Graphical user interface functionalities* paragraph and determine the behavior of the BCI.   


**Matlab Graphical user interface functionalities**

The program uses callback function associated with button presses to interact with the task.
These GUIs include:

1) Single Unit GUI (left column): click on single units to include them into the decoder. This panel will appear after pressing the Update Regression button for the first time. Selecting units with warmer colors (higher R2) provides better decoding performance.
2)  *Update Regression*: to update the calibration of the decoder after performing movements. This button should be pressed every time a substantial amount of samples is performed. It can be used during calibration to control which units give a better tuning (higher R2) or during BCI online mode to improve the calibration. The online calibration mode assumes that the movement is always pointing at the target. (Gilja et al 2012). Internally calibrations done with real movements and during closed-loop are kept separated so it is possible to retrieve data automatically when switching from one modality of calibration to another.  
3) *BCIIDLE*:  to evaluate decoder performance without closing the BCI loop (open-loop). It stores internally real speeds and decoded speeds. 
4) *Check Correlation*: to be used in BCIIDLE mode, by pressing this button the Pearson correlation coefficient is estimated among decoded speeds and real speeds. This button is mainly intended for the application mode where before allowing users to control the decoder, a decent (offline) performance needs to be achieved.
5) *Switch BCI*: after successful calibration to switch to close loop control. It switches to the BCI closed-loop mode. A decent amount of units (30-40) and a decent amount of samples (200-300) needs to be acquired to achieve a decent performance (in offline mode the green cursor should be reliably controlled with the mouse pointer).
6) *Update Decoder*: to be used after a recalibration in closed-loop mode with Updated Regression. Important for real applications not in the simulation mode.  
7) *Load Decoder*: to load a previously calibrated decoder. Note that if used among different experimental sessions
the same number of units should be maintained. Useful for now to restore previous decoders in the same session but potentially useful to use the same decoder across many days.
8) *Stop BCI*: stop the program loop. Should this operation not be successful, to restart the BCImat the VRPN server needs to be manually stopped by doing the following in the Matlab shell:  *vrpn_server('stop_server')*
9) *Reset Calibrator*: to reset the calibration if something went wrong during calibration. It starts to recollect speed and neural samples.  
10) *Shared control*: the cursor control is shared among the computer directly pointing at the target and the neurons. Specify a number between 0-1. 1: full computer control. It is useful during the subject's training phases and to recalibrate the decoder during closed-loop control. The idea is that during real experiments a high level of computer control is introduced to maintain high performance. During the task as the subject acquires proficiency with the control, the amount of control from the computer side is reduced.
11) *Perturbation panel*: rotate the preferred direction of a subset of units. It needs to specify the angle of rotation as well as the percentage of random units that will be rotated and start the perturbation. By rotating the preferred direction of some units during closed-loop control, the direction of movement deviates from the intended movement directions. This panel is intended to introduce visuo-motor rotations of the cursors useful for motor learning studies.

**Other contents of the package**

1. Inside BCI_classes folder: 

 * SimNeurons_2D_velocity.m: this class is used inside BCI_loop.m to generate firing rates of artificial neurons according to a Poisson distribution. During each small movement (e.g 50 ms timestamp), the mean of each Poisson neuron is determined by the baseline firing rate plus the cosine of the actual moving direction and the neuron preferred direction multiplied by the modulation depth. Each neuron preferred direction is determined according to a circular uniform distribution.  This class also uses a hardcoded modulation depth in the physiological range of 4-18 Hz and a baseline firing rate in the range 4-20.  Future releases of this class could include the possibility of specifying these ranges. 

 * Task_parser.m: this simple class is used to handle messages coming from the task controller. It is important for the BCImat to know information about the state of the task    to adapt its behavior accordingly. For example, it could be useful to collect samples of firing rates and positional samples only when the users are engaged with the motor task. In this case, we decided to store the values for calibration online during the last stage of the task (stage 3). 

 * Kalman_calibrator_class.m: this class is used to internally store samples for calibrating a BCI decoder according to the following paper (Wu et al. 2006).
 * Kalman_decoder_class.m: it uses the calibration matrix generated by the Kalman_calibration class to generate position estimation online. Ideally, this class and the calibrator class could be replaced with any other decoder type implementing a similar behavior. 

2. Inside Test_connections:
 * TestVRPNConnection.m: is used to test if a VRPN client connection can be established without implementing all the BCI closed-loop.
 
 This function needs to be called with the following arguments:
 
 test_VRPN_connection(server_address,ismessage).
 
 *server_address* requires the name of the server where the task controller runs, whereas *ismessage* specifies whether we want to read a message from the task controller (ismessage =1) or positional data from the task controller (ismessage =0).  
 
 In practice to check if we are able to retrieve messages it will look like that:  
 
 TestVRPNConnection('TrackerTC@127.0.0.1:6666',0)  
 
 In this case, you should be able to read the stage of the task controller  
 
 it will look like that if we read positional data:   
 
 TestVRPNConnection('TrackerTC@127.0.0.1:6666',1)  
 
 In this case, you should be able to read the position of the cursor on the task controller screen.
 
 * Test_Blackrock.m: is used to test if a connection can be established between the Cereplex system and BCImat .  
This code allows to read online data from cereplex system
https://blackrockneurotech.com/research/wp-content/ifu/LB-0590-3.00-cbMEX-IFU.pdf.  
The code reads spikes data for 5 seconds and restructures data as used inside BCImat. Importantly you should check that if spikes are recorded, the buffer is not empty.


Have fun!

  
**References**

* Georgopoulos, A. P., Kalaska, J. F., Caminiti, R., & Massey, J. T. (1982). On the relations between the direction of two-dimensional arm movements and cell discharge in primate motor cortex [Journal Article]. Journal of Neuroscience, 2(11), 1527–1537. https://doi.org/doi.org/10.1523/JNEUROSCI.02-11-01527.1982.   
* Gilja, V., Nuyujukian, P., Chestek, C. A., Cunningham, J. P., Yu, B. M., Fan, J. M., Churchland, M. M., Kaufman, M. T., Kao, J. C., Ryu, S. I., & Shenoy, K. V. (2012). A high-performance neural prosthesis enabled by control algorithm design [Journal Article]. Nature Neuroscience, 15(12), 1752–1757. https://doi.org/10.1038/nn.3265.   
* Wu, W., Gao, Y., Bienenstock, E., Donoghue, J. P., & Black, M. J. (2006). Bayesian population decoding of motor cortical activity using a kalman filter [Journal Article]. Neural Computation, 18(1), 80–118. https://doi.org/10.1162/089976606774841585

  
Markdown:
[![DOI](https://joss.theoj.org/papers/10.21105/joss.03956/status.svg)](https://doi.org/10.21105/joss.03956)

HTML:
<a style="border-width:0" href="https://doi.org/10.21105/joss.03956">
  <img src="https://joss.theoj.org/papers/10.21105/joss.03956/status.svg" alt="DOI badge" >
</a>

reStructuredText:
.. image:: https://joss.theoj.org/papers/10.21105/joss.03956/status.svg
   :target: https://doi.org/10.21105/joss.03956






