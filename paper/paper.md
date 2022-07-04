---
title: 'BCImat:  a Matlab-based framework for Intracortical Brain-Computer Interfaces and their simulation with an artificial spiking neural network'

tags:
  - Matlab
  - Brain-Computer Interface
  - Closed-Loop
  - Motor Control

authors:
  - name: Enrico Ferrea^[corresponding author]
    affiliation: "1,5"
  - name: Pierre Morel
    affiliation: "1,4" 
  - name: Alexander Gail
    affiliation: "1,2,3" # (Multiple affiliations must be quoted)

affiliations:
 - name: German Primate Center, Sensorimotor Group, Goettingen, Germany
   index: 1
 - name: University of Goettingen, Georg-Elias-Mueller Institute of Psychology, Goettingen, Germany
   index: 2
 - name: Bernstein Center for Computational Neuroscience, Goettingen, Germany
   index: 3
 - name: Univ. Littoral Côte d’Opale, Univ. Artois, Univ. Lille, ULR 7369 - URePSSS - Unité de Recherche Pluridisciplinaire Sport Santé Société, F-62100 Calais, France
   index: 4
 - name: Institute for Neuromodulation and Neurotechnology, University Hospital and University of Tuebingen, Tuebingen, Germany
   index: 5  

date: 16 August 2021
bibliography: paper.bib


---

# Summary
Recent advances in intracortical Brain-Computer Interface (BCI) technology allowed motor disabled patients to partially regain lost motor functions [@RN572;@RN1272;@RN589;@RN569]. In these patients, intact neural activity is extracted from motor-related areas of the cerebral cortex via intracortical implanted electrodes and interpreted by a machine-learning algorithm to control a prosthetic device, thereby bypassing dysfunctional corticospinal projections that resulted, for example, from spinal cord lesions.  BCIs of this type have been and still are being developed mostly in non-human primate animal models. Additionally, they are also used for basic neuroscientific studies in animals to establish a specific experimentally-controlled transformation between the brain area under investigation and a specific behavior [@RN877;@RN219], thereby imposing a direct and controllable causal link between brain activity and behavior. The software introduced here allows true online BCI control of a computer cursor based on physiological signals. Importantly, it also allows realistic real-time neural data simulations from artificial spiking neural network (SNN). With this, all algorithms and the control architecture can be tested in silico identical to the physiological experiment.

# Statement of need
Software for simulating, testing, and applying BCIs based on intracortical recordings of neural spiking activity is not publicly available. Most of the publicly available software for BCIs is designed for applications based on time-continuous electrophysiological signals, like electroencephalographic (EEG) or electrocorticographic (ECoG) signals [@RN1263]. BCImat instead is a Matlab framework for implementing and testing a BCI based on stochastic event time-series, particularly neuronal spiking signals recorded from large numbers of individual neurons that vary at a time-scale of milliseconds. Importantly, BCImat can alternatively use as input simulated data from a built-in artificial spiking neural network (SNN). This allows testing BCI applications with the same algorithm and framework as intended for later use in BCI experiments but before the availability of recordings from implanted animals or human patients. This way, the full online decoding experiment or application can be developed in advance without the need for pre-recorded data files. 
The code is intended for use by anyone wanting to test closed-loop BCI methods or perform intracortical closed-loop BCI experiments. Here the method was tested in rhesus monkeys but it is as well suited for use in other species (mice, humans).

# Overview
The software that defines the BCI framework (BCImat, Fig. 1) interfaces bi-directionally with the software that serves as a simple behavioral task controller (here written in c++, Task Controller Fig. 1). The task controller allows computer-controlled behavioral experiments in which subjects perform center-out reach movements by moving a cursor on a screen with the computer mouse. The BCI framework interacts with the task controller for the purpose of decoder calibration, when first training the machine-learning algorithms to link the physical movements of the hand to the corresponding neural activity patterns, and then later to control cursor movements exclusively based on the neural activity patterns. The communication between the task-controller and the BCI framework is done via the Virtual-Reality Peripheral Network (VRPN) protocol, implementing a client-server application via Transmission Control Protocol (TCP) or User Datagram Protocol (UDP) [@RN1260] on both sides. On the task controller side, a c++ server application is used to provide information to BCImat about the stages of the behavioral task and the position of the cursor on the screen. On the same side, a client application is implemented to update the cursor position on the screen that is read from BCImat. On the BCImat side, a Matlab executable version of the server and client VRPN classes are implemented to read the parameters for calibration and send the decoded parameters. Since the communication is established via Internet Protocol (IP) network, the task controller and the BCI can run on different computers. 
The BCI framework is implemented in object-oriented Matlab to exploit modularity. This makes it possible to use more advanced decoders (e.g., non-linear long-short-term-memory (LSTM) networks, Transformers) as alternatives in order to optimize decoding performance or to provide additional functionalities (e.g., to perturb neural parameters for decoding to experimentally induce neural plasticity in BCI learning studies). Further supporting modularity, BCImat can communicate with other task controllers written in any other programming language provided that VRPN is used to stream and read information to and from the BCI framework. For real intracortical BCI experiments (application mode, Fig. 1), the presented package is implemented for interfacing a Cereplex system (Blackrock, Salt Lake City, USA), but can easily be adapted to other common data acquisition systems. In fact, BCImat can be interfaced with any other recording hardware provided that the same internal buffer structure to store spiking activity in real-time is programed.
To use BCImat without recording hardware, an artificial spiking neural network (SNN) is implemented (simulation mode, Fig. 1). In the simulation mode, we decided to implement the same spike buffer structure of the application mode in order to keep compatibility when switching among the two modes. The task-controller provided here allows performing a center-out reach task with computer mouse movements. While the subject performs the task manually, i.e. by actually physically moving the arm (manual task), the simulated neurons fire accordingly. Mimicking stochastic properties of neural activity in the brain, the firing pattern is simulated as a Poisson process. The frequency of firing is proportional to the cosine of the angle between the direction of movements in the task and their preferred direction. Thereby, the SNN simulates neural response patterns of primate motor cortex during reaching tasks [@RN1261]. 
In practice in the simulation mode, the user would first execute the manual task to calibrate the parameters of the decoding algorithm. After calibration, one will switch from manual task execution to closed-loop “BCI control”. During this closed-loop, the cursor movements are controlled via the decoder output and no longer by real computer mouse movements. At the same time, the user should still perform the task with the mouse, since the cursor movement determines the neurons firing pattern of the SNN, which serves as input to the decoder. The SNN firing depends on its own neural dynamics driven by the cosine model relative to the mouse movement direction. Later, in the application mode, the subject’s brain activity would replace the SNN output, and physical movements would be no longer required to move the cursor. 
To demonstrate functionality and performance, the BCImat code was successfully used with neural activity recorded in motor cortical areas of two rhesus monkeys performing a center-out reach task in a virtual-reality environment, similar to a setup that was previously described [@ferrea2022statistical].  Both animals were housed in social groups with one or two male conspecifics in facilities of the German Primate Center. The facilities provide cage sizes exceeding the requirements by German and European regulations, and access to an enriched environment including wooden structures and various toys. All procedures have been approved by the responsible regional government office [Niedersächsisches Landesamt für Verbraucherschutz und Lebensmittelsicherheit  (LAVES)] under permit numbers 3392 42502-04-13/1100 and comply with German Law and the  European Directive 2010/63/EU regulating use of animals in research. Both animals learned to control the cursor via BCImat. The time that the animals needed to move the cursor to the targets was in the same order of magnitude during manual and BCI task performance in both animals (animal 1: median hand movement time = 404 ms,  animal 1: median BCImat movement time = 585 ms, animal 2: median hand movement time = 418 ms,   animal 2: median BCImat movement time = 743 ms). Note that the observed decrease in performance comparing hand movements with BCI movements is generally expected.
The implemented decoder is a Kalman-Filter for motor control BCI applications [@RN1070]. We also implemented some important BCI features that are frequently used in the literature. These features were found to provide efficient training and better decoding performance. In particular, we implemented (i) the possibility to re-train the Kalman filter during online control [@RN1], (ii) an assisted computer cursor control during closed-loop trials [@RN589] to perform calibration in absence of movements, (iii) rotation of unit preferred directions resulting in movement direction rotations [@RN849], and (iv) the possibility to perform open-loop testing of the decoder (for review see @RN61).


#



![BCImat framework. The BCImat framework interfaces with a task controller to display movements of a cursor on a computer screen and with a neural interface providing spiking signal to ultimately (after decoder calibration) control cursor movements. The neural signal fills an internal spike buffer. The spike buffer is fed with input from an artificial spiking neural network (SNN) for stand-alone (patient independent) experiments (simulation mode), or with external intracortical physiological signals providing neural spike data in real-time (application mode). Our system was tested in application mode with a Matlab executable (mex) code to stream online spikes recorded with a Cereplex system (Blackrock, Salt Lake City, USA). Task controller and BCI framework exchange messages, cursor position or velocities data via VRPN clients and servers. Inside the BCI framework, the cursor velocities are used to calibrate the decoder by regressing them with simultaneously recorded neural activity.  A task state parser is used in BCImat to handle received messages from the task controller. It can be expanded to handle any type of message. Here, for example, information about the completion of a movement is handled to clear the spike buffer regularly to avoid memory overload.](https://user-images.githubusercontent.com/40661882/153216058-aa2697a6-99bd-4da1-b6ca-ab93a3eea501.png)

# Funding:
German Research Foundation (DFG, Germany, grant number FOR-1847-GA1475-B2). Received by AG.
German Research Foundation (DFG, Germany, grant number SFB-889). Received by AG.
Federal Ministry for Education and Research (BMBF, Germany, grant number 01GQ1005C). Received by AG.


# References

