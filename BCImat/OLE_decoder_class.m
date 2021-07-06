classdef OLE_decoder_class < handle;
    properties (Access=private)
        
        position;
        
        K;
        iteration_step;
        dimensions;
        
        
        
    end
    %The following properties can be accessed also by the calibrator class
    properties (SetAccess = ?OLE_calibrator_class)
        preferred_direction;
        baseline_rate;
        modulation_depth;
    end
    
    properties (SetAccess = public)
        neurons;
        velocity;
    end
    
    methods (Access=public)
        
        %Constructor class -> initialize parameters used for decoding
        function obj = OLE_decoder_class(number_dimensions)
            
            
            obj.K = 80;
            obj.position = [0 0 0];
            obj.velocity = [0 0 0];
            obj.preferred_direction = zeros(768,number_dimensions);
            obj.baseline_rate = zeros(1,768);
            obj.modulation_depth = ones(1,768);
            obj.iteration_step = 0.03;
            obj.dimensions = number_dimensions;
            obj.neurons = false(128,6);
            
        end
        
        %This function get called ever iteration and does something after a certain amount of time.
        function obj = loop(obj,task_state,t,spike_data,decoder_on)
            
            
            
            
            if ~isempty(task_state.new_stage) && (strcmp(task_state.stage_type,'LEAVE_FIX_MEM') || strcmp(task_state.stage_type,'PRE_ACQUIRE_MEM_TGT') || strcmp(task_state.stage_type,'ACQUIRE_MEM_TGT'))
                obj.iteration_step = t(end)-t(end-1);
                selected_spikes = (spike_data(end,:) - spike_data(end -1,:))./obj.iteration_step;
                obj.update_velocity(selected_spikes,decoder_on);
                obj.update_position();
                %obj.position = [rand(1) rand(1) 0];
                % obj.velocity = [1 1 1];
                %  display(obj.position)
                
            elseif ~isempty(task_state.new_stage) && strcmp(task_state.stage_type,'HOLD_MEM_TGT')
                obj.position = obj.position ;
                obj.velocity = obj.velocity ;
            else
                obj.position = [0 0 1];
                obj.velocity = [0 0 0];
                
            end
            
            obj.send_position();
            %            obj.time_counter = t(end) + obj.iteration_step;
        end
        
        
        
        
        function obj = update_velocity(obj,firing_rate,decoder_on)
            if decoder_on
                vectorized_neurons = reshape(obj.neurons,1,768);
                n_units = sum(sum(obj.neurons,1));
                obj.preferred_direction(isnan(obj.preferred_direction)) = 0; %clip non fitted values (nan) to -10
                obj.modulation_depth(isnan(obj.modulation_depth)) = 1;
                obj.modulation_depth(obj.modulation_depth == 0) = 1;
                obj.baseline_rate(isnan(obj.baseline_rate)) = 0;
                normalized_rate = ((firing_rate - obj.baseline_rate)./obj.modulation_depth).*vectorized_neurons;
                
                normalized_rate(isnan(normalized_rate)) = 0;
                normalized_rate(normalized_rate<0) = 0;
                neuron_index = find(obj.neurons ==1);
                
                
                decoding_rate = normalized_rate(neuron_index);
                
                obj.velocity = decoding_rate*obj.preferred_direction';
                %            base =  sum(sum(isnan(obj.baseline_rate)));
                %            pref = sum(sum(isnan(obj.preferred_direction)));
                %            modd = sum(sum(isnan(obj.modulation_depth)));
                
                %             base =  obj.baseline_rate;
                %            pref = obj.preferred_direction;
                %            modd = obj.modulation_depth;
                %             vN = sum(isnan(vectorized_neurons));
                %obj.velocity = obj.K*obj.dimensions/n_units*normalized_rate*obj.preferred_direction;
            end
        end
        
        
        
        function obj = update_position(obj)
            if obj.dimensions == 2
                obj.position = obj.position + [obj.iteration_step*obj.velocity, 1];% small hack to fit 2D in 3D
            else
                obj.position = obj.position + obj.iteration_step*obj.velocity;
            end
        end
        
        function obj = send_position(obj)
            
            vrpn_server('set_position',obj.position(1)/1000,obj.position(2)/1000,obj.position(3)./1000);
            
            
        end
        
        %this function is accesed from outside to modify the matrix of
        %neurons to control the cursor. In this specific decoder it is not
        %used and it has moved to the calibrator.
        function set_neurons(obj,channel,unit)
            if (channel>0 & channel<=128 & unit> 0 & unit<= 6 )
                % disp('ok')
                if obj.neurons(channel,unit) == false
                    obj.neurons(channel,unit) = true;
                else
                    obj.neurons(channel,unit) = false;
                end
            end
            
        end
        
        
        
    end % for methods
end %for class


