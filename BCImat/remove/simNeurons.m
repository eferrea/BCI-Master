%%%%%% class for simulate fake monkey neurons
classdef simNeurons < handle  % class should be implemented as a handle class.
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
        True_PD;  MD;  Baseline_rate;  Calibrated_PD;  noise;
        Firing_rate;
    end
    
    %%%%% Methods
    methods (Access=public)
        %%%  constructor function
        function obj = simNeurons(N,varargin) %constructor for the class
            % protected
            obj.time = tic;
            obj.start_time = tic;
            % public
            obj.TimeSinceLastCall = 0;
            obj.TotalTime = 0;
            obj.Number_of_neurons = N;
            obj.poisson_spike = cell(128,7);
            for i=1:128
                obj.poisson_spike{i,1}=['Channel' num2str(i)];
            end
            obj.Baseline_rate = unifrnd(5,10,[1,obj.Number_of_neurons]);
            obj.True_PD = unifrnd(1,360,[1,obj.Number_of_neurons]);
            obj.MD = unifrnd(4,10,[1,obj.Number_of_neurons]);
            obj.noise=unifrnd(-1,1,[1,obj.Number_of_neurons]);
            obj.Firing_rate=[];
        end
        
        %%%%% main function to create Poisson process depending on the last call
        function generate_poisson(obj,task_state,mode,varargin) % mode = 1(Calibrated_PD) or 0(True_PD)
            
            if ~isfield(task_state.parameters, 'REFERENCE_DIRECTION')
                rate = rand(obj.Number_of_neurons,1);
              %  display(NaN)
            else
                direction = task_state.parameters.REFERENCE_DIRECTION;
                %display(direction)
                PD=obj.True_PD;
                rate = obj.Baseline_rate + (obj.MD).* cosd(PD - direction) + obj.noise;
                rate(rate<0)=0; % firing rate of all neurons in specific direction should >0
                obj.Firing_rate=rate;
                % obj.TimeSinceLastCall is the duration of spike train
                obj.TimeSinceLastCall = toc(obj.time); % time since last call "generate_poisson"
                obj.TotalTime = toc(obj.start_time); % time since last call "constructor"
            end
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
            delta_time=1/30000; % sec
            for i=1:obj.Number_of_neurons % traverse each neuron
                random_num=unifrnd(0,1,[1, ceil(obj.TimeSinceLastCall/delta_time)]); % random number
                timestamp = startGenerateTime : delta_time : endGenerateTime;
                P_firing = rate(i) * delta_time; % probability of firing a spike within a short interval
                timestamp(find(random_num >= P_firing))=[];  % delete timestamps which have no firing
                obj.poisson_spike{i,2}=[obj.poisson_spike{i,2} ; timestamp' * 30000];
            end  % end for
        end  % end of generate_poisson function
        
        function display(variable)
            disp(num2str(variable));
            %pause()
        end
        
    end % end of method
end % end of classdefine
