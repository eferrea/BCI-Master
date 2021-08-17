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
    affiliation: "1, 2" 
  - name: Alexander Gail
    affiliation: "1, 2" # (Multiple affiliations must be quoted)

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

# Figure

Figure 1: BCI framework schematics. The BCImat framework interfaces with a task controller to display movements of a cursor on a computer screen and with a neural interface providing spiking signal to ultimately (after decoder calibration) control cursor movements. The neural signal fills an internal spike buffer. The spike buffer can be interfaced with an artificial spiking neural network (SNN) for stand-alone (patient independent) experiments (simulation mode), as well as with an external physiological intracortical interface providing spike data in real-time (application mode). Our system was tested in application mode with a Matlab executable (mex) code to stream online spikes recorded with a Cereplex system (Blackrock, Salt Lake City, USA). Task controller and BCI framework exchange messages, cursor position or velocities data via VRPN clients and servers. Inside the BCI framework, the cursor velocities are used to calibrate the decoder by regressing them with simultaneously recorded neural activity.  A task state parser is used internally to the framework to handle received messages from the BCI. It can be expanded to handle any type of message. Here for example movement stage information and position of the target are handled as well as to clear the spike buffer regularly to avoid excessive memory overload.

# References

@article{RN572,
   author = {Aflalo, T. and Kellis, S. and Klaes, C. and Lee, B. and Shi, Y. and Pejsa, K. and Shanfield, K. and Hayes-Jackson, S. and Aisen, M. and Heck, C. and Liu, C. and Andersen, R. A.},
   title = {Neurophysiology. Decoding motor imagery from the posterior parietal cortex of a tetraplegic human},
   journal = {Science},
   volume = {348},
   number = {6237},
   pages = {906-10},
   ISSN = {1095-9203 (Electronic)
0036-8075 (Linking)},
   DOI = {10.1126/science.aaa5417},
   url = {http://www.ncbi.nlm.nih.gov/pubmed/25999506},
   year = {2015},
   type = {Journal Article}
}

@article{RN1272,
   author = {Ajiboye, A. B. and Willett, F. R. and Young, D. R. and Memberg, W. D. and Murphy, B. A. and Miller, J. P. and Walter, B. L. and Sweet, J. A. and Hoyen, H. A. and Keith, M. W. and Peckham, P. H. and Simeral, J. D. and Donoghue, J. P. and Hochberg, L. R. and Kirsch, R. F.},
   title = {Restoration of reaching and grasping movements through brain-controlled muscle stimulation in a person with tetraplegia: a proof-of-concept demonstration},
   journal = {Lancet},
   volume = {389},
   number = {10081},
   pages = {1821-1830},
   ISSN = {1474-547X (Electronic)
0140-6736 (Linking)},
   DOI = {10.1016/S0140-6736(17)30601-3},
   url = {https://www.ncbi.nlm.nih.gov/pubmed/28363483},
   year = {2017},
   type = {Journal Article}
}

@article{RN589,
   author = {Collinger, J. L. and Wodlinger, B. and Downey, J. E. and Wang, W. and Tyler-Kabara, E. C. and Weber, D. J. and McMorland, A. J. and Velliste, M. and Boninger, M. L. and Schwartz, A. B.},
   title = {High-performance neuroprosthetic control by an individual with tetraplegia},
   journal = {Lancet},
   volume = {381},
   number = {9866},
   pages = {557-64},
   ISSN = {1474-547X (Electronic)
0140-6736 (Linking)},
   DOI = {10.1016/S0140-6736(12)61816-9},
   url = {http://www.ncbi.nlm.nih.gov/pubmed/23253623},
   year = {2013},
   type = {Journal Article}
}

@article{RN1049,
   author = {Ferrea, Enrico and Morel, Pierre and Franke, Joscha and Gail, Alexander},
   title = {Statistical determinants of visuomotor adaptation in a virtual reality three-dimensional environment},
   journal = {bioRxiv},
   year = {2021},
   type = {Journal Article}
}

@article{RN1261,
   author = {Georgopoulos, Apostolos P and Kalaska, John F and Caminiti, Roberto and Massey, Joe T},
   title = {On the relations between the direction of two-dimensional arm movements and cell discharge in primate motor cortex},
   journal = {Journal of Neuroscience},
   volume = {2},
   number = {11},
   pages = {1527-1537},
   ISSN = {0270-6474},
   year = {1982},
   type = {Journal Article}
}

@article{RN1,
   author = {Gilja, V. and Nuyujukian, P. and Chestek, C. A. and Cunningham, J. P. and Yu, B. M. and Fan, J. M. and Churchland, M. M. and Kaufman, M. T. and Kao, J. C. and Ryu, S. I. and Shenoy, K. V.},
   title = {A high-performance neural prosthesis enabled by control algorithm design},
   journal = {Nat Neurosci},
   volume = {15},
   number = {12},
   pages = {1752-7},
   ISSN = {1546-1726 (Electronic)
1097-6256 (Linking)},
   DOI = {10.1038/nn.3265},
   url = {http://www.ncbi.nlm.nih.gov/pubmed/23160043},
   year = {2012},
   type = {Journal Article}
}

@article{RN569,
   author = {Hochberg, L. R. and Bacher, D. and Jarosiewicz, B. and Masse, N. Y. and Simeral, J. D. and Vogel, J. and Haddadin, S. and Liu, J. and Cash, S. S. and van der Smagt, P. and Donoghue, J. P.},
   title = {Reach and grasp by people with tetraplegia using a neurally controlled robotic arm},
   journal = {Nature},
   volume = {485},
   number = {7398},
   pages = {372-5},
   ISSN = {1476-4687 (Electronic)
0028-0836 (Linking)},
   DOI = {10.1038/nature11076},
   url = {http://www.ncbi.nlm.nih.gov/pubmed/22596161},
   year = {2012},
   type = {Journal Article}
}

@article{RN849,
   author = {Jarosiewicz, B. and Chase, S. M. and Fraser, G. W. and Velliste, M. and Kass, R. E. and Schwartz, A. B.},
   title = {Functional network reorganization during learning in a brain-computer interface paradigm},
   journal = {Proc Natl Acad Sci U S A},
   volume = {105},
   number = {49},
   pages = {19486-91},
   ISSN = {1091-6490 (Electronic)
0027-8424 (Linking)},
   DOI = {10.1073/pnas.0808113105},
   url = {https://www.ncbi.nlm.nih.gov/pubmed/19047633},
   year = {2008},
   type = {Journal Article}
}

@article{RN877,
   author = {Koralek, A. C. and Jin, X. and Long, J. D., 2nd and Costa, R. M. and Carmena, J. M.},
   title = {Corticostriatal plasticity is necessary for learning intentional neuroprosthetic skills},
   journal = {Nature},
   volume = {483},
   number = {7389},
   pages = {331-5},
   ISSN = {1476-4687 (Electronic)
0028-0836 (Linking)},
   DOI = {10.1038/nature10845},
   url = {https://www.ncbi.nlm.nih.gov/pubmed/22388818},
   year = {2012},
   type = {Journal Article}
}

@article{RN219,
   author = {Sadtler, P. T. and Quick, K. M. and Golub, M. D. and Chase, S. M. and Ryu, S. I. and Tyler-Kabara, E. C. and Yu, B. M. and Batista, A. P.},
   title = {Neural constraints on learning},
   journal = {Nature},
   volume = {512},
   number = {7515},
   pages = {423-6},
   ISSN = {1476-4687 (Electronic)
0028-0836 (Linking)},
   DOI = {10.1038/nature13665},
   url = {http://www.ncbi.nlm.nih.gov/pubmed/25164754},
   year = {2014},
   type = {Journal Article}
}

@article{RN61,
   author = {Shenoy, K. V. and Carmena, J. M.},
   title = {Combining decoder design and neural adaptation in brain-machine interfaces},
   journal = {Neuron},
   volume = {84},
   number = {4},
   pages = {665-80},
   ISSN = {1097-4199 (Electronic)
0896-6273 (Linking)},
   DOI = {10.1016/j.neuron.2014.08.038},
   url = {http://www.ncbi.nlm.nih.gov/pubmed/25459407},
   year = {2014},
   type = {Journal Article}
}

@article{RN1263,
   author = {Stegman, Pierce and Crawford, Chris S and Andujar, Marvin and Nijholt, Anton and Gilbert, Juan E},
   title = {Brain–computer interface software: A review and discussion},
   journal = {IEEE Transactions on Human-Machine Systems},
   volume = {50},
   number = {2},
   pages = {101-115},
   ISSN = {2168-2291},
   year = {2020},
   type = {Journal Article}
}

@inproceedings{RN1260,
   author = {Taylor, Russell M and Hudson, Thomas C and Seeger, Adam and Weber, Hans and Juliano, Jeffrey and Helser, Aron T},
   title = {VRPN: a device-independent, network-transparent VR peripheral system},
   booktitle = {Proceedings of the ACM symposium on Virtual reality software and technology},
   pages = {55-61},
   type = {Conference Proceedings}
}

@article{RN1070,
   author = {Wu, Wei and Gao, Yun and Bienenstock, Elie and Donoghue, John P and Black, Michael J},
   title = {Bayesian population decoding of motor cortical activity using a Kalman filter},
   journal = {Neural computation},
   volume = {18},
   number = {1},
   pages = {80-118},
   ISSN = {0899-7667},
   year = {2006},
   type = {Journal Article}
}


