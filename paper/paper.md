---
title: 'BCImat:  a Matlab-based framework for Intracortical Brain-Computer Interfaces and their simulation with an artificial spiking neural network'

tags:
  - Matlab
  - Brain-Computer Interface
  - Closed-Loop
  - Motor Control

authors:
  - name: Enrico Ferrea^[corresponding author]
    affiliation: 1
  - name: Pierre Morel
    affiliation: "1, 4" 
  - name: Alexander Gail
    affiliation: "1, 2,3" # (Multiple affiliations must be quoted)

affiliations:
 - name: German Primate Center, Sensorimotor Group, Goettingen, Germany
   index: 1
 - name: University of Goettingen, Georg-Elias-Mueller Institute of Psychology, Goettingen, Germany
   index: 2
 - name: Bernstein Center for Computational Neuroscience, Goettingen, Germany
   index: 3
 - name: Univ. Littoral Côte d’Opale, Univ. Lille, Univ. Artois, ULR 7369 - URePSSS - Unité de Recherche Pluridisciplinaire Sport Santé Société, F-59140 Dunkerque, France
   index: 4

date: 16 August 2021
bibliography: paper.bib


---

# Summary
Recent advances in intracortical Brain-Computer Interface (BCI) technology allowed motor disabled patients to partially regain lost motor functions \cite{RN572, 1272, 589, 569}. In these patients, intact neural activity is extracted from motor-related areas of the cerebral cortex via intracortical implanted electrodes and interpreted by a machine-learning algorithm to control a prosthetic device, thereby bypassing dysfunctional corticospinal projections that resulted, for example, from spinal cord lesions.  BCIs are also used for basic neuroscientific studies to establish a specific transformation between the brain area under investigation and a specific behavior \cite{RN877, 219} and therefore imposing a direct causal link between them. The software introduced here allows true online BCI control of a computer cursor based on physiological signals (e.g. from patients) as well as realistic real-time simulations for testing all algorithms based on artificial spiking neural network (SNN) data using the identical control architecture.

# Statement of need
Most of the publicly available software for BCIs is designed for applications based on time-continuous electrophysiological signals, like electroencephalographic (EEG) or electrocorticographic (ECoG) signals \cite{RN1263} and requires existing recording possibilities or pre-recorded data for testing. BCImat instead is a MATLAB framework for implementing and testing a BCI which is based on stochastic event time-series, particularly neuronal spiking signals recorded from large numbers of individual neurons that vary at a time-scale of milliseconds. For example, BCImat can use intracortical single-neuron signals acquired with a Cereplex system (Blackrock, Salt Lake City, USA). Importantly, BCImat can alternatively use the input from a built-in artificial spiking neural network (SNN) for simulating the later online BCI control. This allows testing BCI applications with the same algorithm and framework as intended for later use in patients, but before the availability of implanted subjects and specific recording hardware. This way, the full online decoding experiment or application can be developed in advance without the need for pre-recorded data files. 
The code is intended for use by anyone wanting to test closed-loop BCI methods or perform intracortical closed-loop BCI experiments.

# Overview
The BCI framework (Fig.1) interfaces bidirectionally with a simple behavioral task controller (here written in c++) allowing to perform center-out reach movements for decoder calibration and then to control cursor movements via the neural activity. The communication between the task-controller and the BCI framework is done via the Virtual-Reality Peripheral Network (VRPN) protocol, implementing a client-server application via TCP or UDP \cite{RN1260} on both sides. On the task controller side, a standard c++ client-server application is used. On the BCImat side, a MATLAB executable version of the server and client VRPN classes are implemented to read the parameters for calibration and send the decoded parameters. Since the communication is established via IP network, the task controller and the BCI can run on different computers. 
The framework is implemented in object-oriented MATLAB to exploit modularity. This makes it possible to interchange different decoders or to optimize decoding performance or to provide additional functionalities, for example, to perturb neural parameters for decoding in BCI learning experiments. Further supporting modularity, BCImat can communicate with other task controllers written in any other programming language provided that VRPN is used to stream and read information to and from the BCI framework. In addition, BCImat can be interfaced with any other recording hardware provided that spiking activity can be streamed in real-time and the Trial Spike Buffer format maintained.
To use BCImat without recording hardware, an artificial spiking neural network (SNN) is implemented. The task-controller provided here allows performing a center-out reach task with computer mouse movements. While the subject performs the manual task, the simulated neurons fire accordingly with a Poisson process the frequency of which is proportional to the cosine of the angle between the direction of movements in the task and their preferred direction. Thereby, the SNN simulates neural response patterns of primate motor cortex during reaching tasks \cite{RN1261}. In practice, the user would first execute the manual motor task to calibrate the parameters of the decoding algorithm. Once switching from manual task execution to “BCI control” after calibration, the decoder output, i.e., the computer cursor movements, determines the neurons firing pattern depending on their own dynamics (cosine model) relative to the actual movement direction. During this closed-loop online control in the simulation mode, the cursor movements are therefore controlled via the decoder by the SNN and no longer by real computer mouse movements. Later, in the application mode, the subject’s brain activity would replace the SNN output. The code was successfully used from extracted neural activity of rhesus monkeys performing a similar center-out reach as previously described in a virtual-reality environment \cite{RN1049}.  
The implemented decoder is a Kalman-Filter for motor control BCI applications \cite{RN1070}.   We also implemented some important BCI features that are frequently used in the literature to provide efficient training and better decoding performance. In particular, we implemented the possibility to re-train the Kalman filter during online control \cite{RN1}, an assisted computer cursor control during closed-loop trials \cite{RN589} to perform calibration in absence of movements, rotation of unit preferred directions resulting in movement direction rotations \cite{RN849}, and the possibility to perform open-loop testing of the decoder (for review see \cite{RN61}).


##
![Figure 1: BCI framework schematics. The BCImat framework interfaces with a task controller to display movements of a cursor on a computer screen and with a neural interface providing spiking signal to ultimately (after decoder calibration) control cursor movements. The neural signal fills an internal spike buffer. The spike buffer can be interfaced with an artificial spiking neural network (SNN) for stand-alone (patient independent) experiments (simulation mode), as well as with an external physiological intracortical interface providing spike data in real-time (application mode). Our system was tested in application mode with a Matlab executable (mex) code to stream online spikes recorded with a Cereplex system (Blackrock, Salt Lake City, USA). Task controller and BCI framework exchange messages, cursor position or velocities data via VRPN clients and servers. Inside the BCI framework, the cursor velocities are used to calibrate the decoder by regressing them with simultaneously recorded neural activity.  A task state parser is used internally to the framework to handle received messages from the BCI. It can be expanded to handle any type of message. Here for example movement stage information and position of the target are handled as well as to clear the spike buffer regularly to avoid excessive memory overload.](Fig1.png)

# References

