%%%%%% class for simulate fake monkey neurons
% It randomly generates modulation depth, preferred direction and
%baseline rate of a specified number of cells. The cell firing dynamic is
%dictate by a cosine model (Georgopoulos et al., 1982).
% @ E.Ferrea ,2015 .
%At the actual implementation status, this class takes only the number of units as
%input. 

classdef simNeurons_2D_velocity < handle  % class should be implemented as a handle class. 
    % All copies of a given handle object refer to the same data.
    
    properties (Access=protected)
        time;
        start_time;
    end
    
    properties (Access = public)
        poisson_spike;
        TimeSinceLastCall;
        TotalTime;
        Number_of_neurons;
        preferred_direction;  baseline_rate;  modulation_depth; Calibrated_PD;  noise;
        Firing_rate;
        position_index;
        speed;
    end
    
    %%%%% Methods
    methods (Access=public)
        %%%  constructor function
        function obj = simNeurons_2D_velocity(N,varargin) %constructor for the class
            % protected memeber
            obj.time = tic;
            obj.start_time = tic;
            % public member
            obj.TimeSinceLastCall = 0;
            obj.TotalTime = 0;
            obj.poisson_spike = cell(128,7);
            
              for i=1:128
                  obj.poisson_spike{i,1}=['Channel' num2str(i)];
              end
            obj.Number_of_neurons = N; % neurons number
            %obj.noise=unifrnd(-1,1,[1,obj.Number_of_neurons]);
           obj.noise = 0
            
            obj.Firing_rate=[];
            obj.position_index = int16((896-129).*rand(N,1) + 129);
            optargin = size(varargin, 2); % number of varargin's inputs
            switch optargin
                case 0  % Number of neurons only
                     neuron_on_sphere = 1;
                    while neuron_on_sphere <= obj.Number_of_neurons
                        vector = unifrnd(-1,1,[2,1]);
                        norm_of_vector = norm(vector);
                        if norm_of_vector < 1
                           obj.preferred_direction(:,neuron_on_sphere) = vector./norm_of_vector;
                           neuron_on_sphere = neuron_on_sphere+ 1;
                        end
                    end
                  %obj.preferred_direction = unifrnd(-1,1,[3,obj.Number_of_neurons]);
%                    for k=1:obj.Number_of_neurons
%                   obj.preferred_direction(:,k)=obj.preferred_direction(:,k)/norm(obj.preferred_direction(:,k));
%                   end 
                  
                  obj.baseline_rate = unifrnd(4,18,[1,obj.Number_of_neurons]);
                  obj.modulation_depth = unifrnd(4,20,[1,obj.Number_of_neurons]);
%                   mu = 77;
%                   sigma = 97;
                 
                   %obj.speed = normrnd(mu,sigma,[1,obj.Number_of_neurons]);
                   obj.speed = unifrnd(2,80,[1,obj.Number_of_neurons]);
                case 1  % Number and PD
                  if size(varargin{1},2) ~= N  % columns of PD should = N
                     error ('Error: Dismatch Input');
                  else  
                  obj.preferred_direction = varargin{1};
                  obj.baseline_rate = unifrnd(5,10,[1,obj.Number_of_neurons]);
                  obj.modulation_depth = unifrnd(4,10,[1,obj.Number_of_neurons]);
                  end
                case 2  % Number and PD and Baseline
                  if size(varargin{1},2) ~= N || length(varargin{2}) ~= N
                     error ('Error: Dismatch Input');
                  else  
                  obj.preferred_direction = varargin{1};
                  obj.baseline_rate = varargin{2};
                  obj.modulation_depth = unifrnd(5,25,[1,obj.Number_of_neurons]);
                  %obj.modulation_depth = unifrnd(2,80,[1,obj.Number_of_neurons]);
                  end
                case 3  % Number and PD and Baseline and modulation_depth
                  if size(varargin{1},2) ~= N || length(varargin{2}) ~= N || length(varargin{3}) ~= N
                     error ('Error: Dismatch Input');
                  else 
                  obj.preferred_direction = varargin{1};
                  obj.baseline_rate = varargin{2};
                  obj.modulation_depth = varargin{3};
                  end
            end  % end of switch
        end % end of constructor
        
        %%%%% main function to create Poisson process depending on the last call
        function generate_poisson(obj,velocity_vector,mode,varargin) % mode = 1(Calibrated_PD) or 0(preferred_direction)
           %normalize the vector
           velocity_vector = velocity_vector./norm(velocity_vector);
           %velocity_vector = velocity_vector; %using this second formula will make the control almost perfect but physiologically not plausible.
           % the changes will extend the rate to higher firing rate values.
           
           %remove NaN elements due to zero vector normalization
           if (isnan(sum(velocity_vector)))
              
               velocity_vector = [0 0];
           end
           
            rate = obj.baseline_rate + (obj.modulation_depth).* (velocity_vector * obj.preferred_direction) + obj.noise;
           
            rate(rate<0)=0; % firing rate of all neurons in specific direction should >0
            obj.Firing_rate=rate;
            % obj.TimeSinceLastCall is the duration of spike train
            obj.TimeSinceLastCall = toc(obj.time); % time since last call "generate_poisson"
            obj.TotalTime = toc(obj.start_time); % time since last call "constructor"
            %%% choose mode (keep or delete)   
            switch mode
                case 0
                % keep previous spike data
                obj.poisson_spike = obj.poisson_spike;
                startGenerateTime = obj.TotalTime - obj.TimeSinceLastCall;
                endGenerateTime=obj.TotalTime;
                case 1    
                % re-construct the "poisson_spike" memeber
                startGenerateTime = 0;
                endGenerateTime = obj.TimeSinceLastCall;
                obj.poisson_spike = cell(128,7); % public
                for i=1:128
                    obj.poisson_spike{i,1}=['Channel' num2str(i)];
                end  
            end
            obj.time = tic; % re-timing duration of spike train
            %%% generate spike
            delta_time=1/30000; % sec. Fs chosen to keep same sampling as cereplex.
            for i=1:obj.Number_of_neurons % traverse each neuron
               random_num=unifrnd(0,1,[1, ceil(obj.TimeSinceLastCall/delta_time)]); % random number
               timestamp = startGenerateTime : delta_time : endGenerateTime; 
               P_firing = rate(i) * delta_time; % probability of firing a spike within a short interval
               timestamp(find(random_num >= P_firing))=[];  % delete timestamps which have no firing
               obj.poisson_spike{obj.position_index(i)}=[obj.poisson_spike{obj.position_index(i)} ; timestamp' * 30000];
            end  % end for
        end  % end of generate_poisson function           
    end % end of method    
end % end of classdefine
