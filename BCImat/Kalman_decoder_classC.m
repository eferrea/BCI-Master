classdef Kalman_decoder_class < handle;
    properties (Access=private)
        
        
        K;
        iteration_step;
        dimensions;
        X_prior;
        firing_rate;
        Z;
        X;
        delay;
        t_movement;
        expected_total_samples;
        correlation_counter;
        correlation_velocity;
        bci_correlation_velocity;
        max_corr_samples;
        
        
        
        
        
        
    end
    %The following properties can be accessed also by the calibrator class
    properties (SetAccess = ?Kalman_calibrator_class)
        preferred_direction;
        baseline_rate;
        modulation_depth;
        A;
        W;
        H;
        Q;
        P;
        neurons;
        
    end
    
    properties (SetAccess = public)
        position;
        velocity;
        n_neurons;
        X_update;
        filename;
        sample;
        check_correlation;
        
    end
    
    methods (Access=public)
        
        %Constructor class -> initialize parameters used for decoding
        function obj = Kalman_decoder_class(dimensions,sample_size,max_exp_duration,delay,max_samples)
            
            obj.expected_total_samples = ceil(max_exp_duration/sample_size);
            obj.K = 0;
            obj.position = zeros(obj.expected_total_samples,3);
            obj.velocity = zeros(obj.expected_total_samples,3);
            obj.preferred_direction = zeros(768,dimensions);
            obj.baseline_rate = zeros(1,768);
            obj.modulation_depth = ones(1,768);
            obj.iteration_step = 0;
            obj.dimensions = dimensions;
            obj.neurons = false(128,6);
            obj.P = 0;
            obj.X_update = zeros(7,1);
            obj.X_update(1,1) = 1;
            obj.delay = delay;
            obj.firing_rate = zeros(obj.expected_total_samples,768);
            obj.sample = obj.delay;
            obj.correlation_counter  = 1;
            obj.max_corr_samples = max_samples;
            obj.correlation_velocity = zeros(3,obj.max_corr_samples);
            obj.bci_correlation_velocity = zeros(3,obj.max_corr_samples);
            obj.check_correlation = false;
            
        end
        
        %This function get called ever iteration and does something after a certain amount of time.
        function obj = loop(obj,task_state,t,interval,spike_data,decoder_on,isIDLE,target_position,p)
                obj.sample = obj.sample +1;      
            %Start to move only after the go cue and if the decoder is on
            if (~isempty(task_state.new_stage) && decoder_on) && (strcmp(task_state.stage_type,'LEAVE_FIX_MEM_BCI_1') || strcmp(task_state.stage_type,'PRE_ACQUIRE_MEM_TGT_BCI_1') || strcmp(task_state.stage_type,'ACQUIRE_MEM_TGT_BCI_1')...
                  ||  strcmp(task_state.stage_type,'HOLD_MEM_TGT_BCI_1'))
                
                obj.t_movement(obj.sample) = t; %check non zero entries of this vector
                obj.firing_rate(obj.sample,:) = spike_data./interval; %firing rates are stored only when the cursor is supposed to move 
%                 if (task_state.new_stage)
%                     obj.P = 0;
%                 end
                obj.UpdateVelocity(isIDLE,target_position,p);
                
%                 %Stop the cursor when hit the target
%             elseif (~isempty(task_state.new_stage) && decoder_on) && strcmp(task_state.stage_type,'HOLD_MEM_TGT_BCI_1')
%                obj.position(obj.sample,:) = obj.position(obj.sample,:) ;
%                obj.velocity(obj.sample,:) = [0 0 0];
%                 
                
            else
                % Put cursur at zero position at the beginning of the trial
                % and when BCI is not running
                obj.position(obj.sample,:) = [0 -40 100];
                obj.velocity(obj.sample,:) = [0 0 0];
                obj.X_update = [1; obj.position(obj.sample,:)'; obj.velocity(obj.sample,:)'];
                     
            end
            %Send the updated position to the task controller
            obj.send_position(isIDLE);
            
            
        end
           
        %Velocity Kalman Filter fumction
        function obj = UpdateVelocity(obj,isIDLE,target_position,p)
            %Kalman filter parameters:

            obj.Z = obj.firing_rate(obj.sample,find(obj.neurons ==1))'; %the delay takes into account the delay between firing rates and actuation
            obj.X = obj.X_update; %update from previous stage
            
            % I. time update the equations
            obj.X_prior = obj.A*obj.X; %a priori estimate of the state
            obj.P = obj.A*obj.P*obj.A' + obj.W; %error covariance matrix
            
            %We presume that the user internalize the filter's estimate of
            %cursor position  with complete certainty at time t.
            obj.P (1:4,:) = 0;
            obj.P (5:7,1:4) = 0;
            
            % II Measurements update equations
            obj.K = obj.P*obj.H'*inv(obj.H*obj.P*obj.H' + obj.Q);
            obj.X_update = obj.X_prior + obj.K*(obj.Z-obj.H*obj.X_prior);
            
            obj.P = (eye(size(obj.W)) -obj.K*obj.H)*obj.P;
           % obj.position(obj.sample,:) = obj.X_update(2:4)';
           % obj.velocity(obj.sample,:) = obj.X_update(5:7)';
%             if(~isIDLE)
%               obj.X_update(5:7) = obj.X_update(5:7);%-0.15*obj.position(obj.sample,:)';
%             end

            dt =0.05;
            obj.velocity(obj.sample,:) = obj.X_update(5:7)';
            obtimal_vector = target_position-obj.position(obj.sample-1,:);
            obj.position(obj.sample,:) = obj.position(obj.sample-1,:) +dt*norm(obj.velocity(obj.sample,:))*(obtimal_vector./norm(obtimal_vector)*p + (1-p)*obj.velocity(obj.sample,:)./norm(obj.velocity(obj.sample,:)));
            
            obj.X_update(2:4) = obj.position(obj.sample,:)';
             
            
                    
            
        end
        
         function OnlineCorrelation(obj,task_state,velocity_vector,decoder_on,isIDLE)
            
            %Output the actual decoder performance stor values in two variables and compare them
            %in the future will be better to store indexes and retrieve
            %data from proper variables.
            if(decoder_on && isIDLE) && (strcmp(task_state.stage_type,'ACQUIRE_MEM_TGT_BCI_1')) %|| strcmp(task_state.stage_type,'HOLD_MEM_TGT_BCI_1'))
                
                obj.correlation_velocity(1,obj.correlation_counter) =  velocity_vector(1,1);
                obj.correlation_velocity(2,obj.correlation_counter) =  velocity_vector(2,1);
                obj.correlation_velocity(3,obj.correlation_counter) =  velocity_vector(3,1);
                
                obj.bci_correlation_velocity(1,obj.correlation_counter) = obj.velocity(obj.sample-obj.delay,1);
                obj.bci_correlation_velocity(2,obj.correlation_counter) = obj.velocity(obj.sample-obj.delay,2);
                obj.bci_correlation_velocity(3,obj.correlation_counter) = obj.velocity(obj.sample-obj.delay,3);
                %display('ok')
                % display correlation values at button press or every max
                % corr samples
                obj.correlation_counter = obj.correlation_counter +1;
               
            end
             
                if(obj.check_correlation || obj.correlation_counter >= obj.max_corr_samples)
                    % check_correlation = false;
                    rx = corr(obj.correlation_velocity(1,1:obj.correlation_counter )', obj.bci_correlation_velocity(1,1:obj.correlation_counter )');
                    ry = corr(obj.correlation_velocity(2,1:obj.correlation_counter )', obj.bci_correlation_velocity(2,1:obj.correlation_counter )');
                    rz = corr(obj.correlation_velocity(3,1:obj.correlation_counter )', obj.bci_correlation_velocity(3,1:obj.correlation_counter )');
                    
                    disp(['rx: ' num2str(rx) ' ry:' num2str(ry) ' rz:' num2str(rz) ' Samples:' num2str(obj.correlation_counter) ])
                    obj.correlation_counter  = 1;
                    obj.check_correlation = false;
                end
                
                
            
        end
        
        
        %the decoder is saved at the end of the experiment
        function obj = SaveDecoder(obj)
            
            [year,month,day] =  ymd(datetime);
            [hour,minute,second] = hms(datetime);
            filename_root = [num2str(year) '-' num2str(month) '-' num2str(day) '_' num2str(hour) '-'  num2str(minute) '-'  num2str(ceil(second))]
            obj.filename = [filename_root '_decoded_values.mat']
            %save decoded values
            Z_decoder = obj.Z;
            X_decoder = obj.X; 
            time_decoder = obj.t_movement;
            
            save(obj.filename,'time_decoder','X_decoder','Z_decoder')
             pause(1)       
        end
        
        %send the cursor position to th etask controller
        function obj = send_position(obj,isIDLE)
           %The delay is recomended only on the open-loop control (isIDLE
           %state)
            if (isIDLE)
           vrpn_server('set_position',obj.position(obj.sample - obj.delay,1)/1000,obj.position(obj.sample - obj.delay,2)/1000,obj.position(obj.sample - obj.delay,3)./1000);
           else
             vrpn_server('set_position',obj.position(obj.sample,1)/1000,obj.position(obj.sample,2)/1000,obj.position(obj.sample,3)./1000);  
           end
        end
        
        % This function will erase the decoder to values 
        function obj = ResetDecoder(obj)
            
           
            obj.K = 0;
           obj.position = zeros(obj.expected_total_samples,3);
            obj.velocity = zeros(obj.expected_total_samples,3);      
            obj.neurons = false(128,6);
            obj.P = 0;
            obj.X_update = zeros(7,1);
            obj.X_update(1,1) = 1;
            obj.firing_rate = zeros(obj.expected_total_samples,768);
            obj.sample = obj.delay +1;
            
            
        end
            
%         %this function is accesed from outside to modify the matrix of
%         %neurons to control the cursor. In this specific decoder it is not
%         %used and it has moved to the calibrator.
%         function set_neurons(obj,channel,unit)
%             if (channel>0 & channel<=128 & unit> 0 & unit<= 6 )
%                 % disp('ok')
%                 if obj.neurons(channel,unit) == false
%                     obj.neurons(channel,unit) = true;
%                 else
%                     obj.neurons(channel,unit) = false;
%                 end
%             end
%             
%         end
%         
        
        
    end % for methods
end %for class


