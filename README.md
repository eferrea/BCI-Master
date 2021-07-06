# BCImat a Matlab Brain Computer Interface
Description

BCImat is a Matlab program implementinhg a BCI decoder to decode movement intetions via two types of interfaces:
1) a simulated set of cosine tuned neurons
2) a real neural interface from Blackrock 128 channel recording system that using the cbmex .

The simulated set of units class generate spikes according to a poisson distribution whose rate is dictated by actual mouse movement performed in a basic c++ human interface.
For each neuron a random modulation depth, a baseline firing rate and a preferred direction is randomly chosen. During real movements the rate is determined by the dot products of the actual movement direction 
and the preferred direction scaled by the modulation depth and summed to the baseline foring rate. 
     

  

How to build BCImat example
BCImat comes with a c++ a simple task controller interfacing with the BCImat. allowing users to perform sequential reacheas always starting from a cenral fixation point.
The c++ 
