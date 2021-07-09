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
        time;
        expected_total_samples;
        correlation_counter;
        correlation_velocity;
        bci_correlation_velocity;
        max_corr_samples;
        dt;
        rotation_counter;
        
        
        fileID_decoder;
        printfFormatHeader;
        printfFormatBody;
        
        
        
        
        
        
    end
    %The following properties can be accessed also by the calibrator class
    properties (SetAccess = ?Kalman_calibrator_class)
        preferred_direction;
        baseline_rate;
        modulation_depth;
        
        A;
        W;
        Q;
        P;
        neurons;
        H;
        H_reset;
        fixation_position;
        
    end
    
    properties (SetAccess = public)
        position;
        velocity;
        n_neurons;
        X_update;
        sample;
        check_correlation;
         
        
    end
    
    methods (Access=public)
        
        %Constructor class -> initialize parameters used for decoding
        function obj = Kalman_decoder_class(dimensions,sample_size,max_exp_duration,delay,max_samples)
            
            obj.expected_total_samples = ceil(max_exp_duration/sample_size);
            obj.K = 0;
            obj.position = zeros(obj.expected_total_samples,2);
            obj.velocity = zeros(obj.expected_total_samples,2);
            %             obj.X_decoder = zeros(7,obj.expected_total_samples);
            %             obj.Z_decoder = zeros(7,obj.expected_total_samples);
            obj.preferred_direction = zeros(768,dimensions);
            obj.baseline_rate = zeros(1,768);
            obj.modulation_depth = ones(1,768);
            obj.iteration_step = 0;
            obj.dimensions = dimensions;
            obj.neurons = false(128,6);
            obj.P = 0;
            obj.X_update = zeros(5,1);
            obj.X_update(1,1) = 1;
            obj.delay = delay;
            obj.firing_rate = zeros(obj.expected_total_samples,768);
            obj.sample = obj.delay;
            obj.correlation_counter  = 0;
            obj.max_corr_samples = max_samples;
            obj.correlation_velocity = zeros(3,obj.max_corr_samples);
            obj.bci_correlation_velocity = zeros(3,obj.max_corr_samples);
            obj.check_correlation = false;
            obj.dt = sample_size;
            obj.rotation_counter = 1;
            obj.fixation_position = [0 0];
            
            
            [year,month,day] =  ymd(datetime);
            [hour,minute,second] = hms(datetime);
            filename_root = [num2str(year) '-' num2str(month) '-' num2str(day) '_' num2str(hour) '-'  num2str(minute) '-'  num2str(int8(second))];
            
            filename_decoder = [filename_root '_decoder.txt'];
            
            obj.fileID_decoder = fopen(filename_decoder,'at');
            obj.printfFormatHeader = ['%6s' '%6s\n'];
            obj.printfFormatBody = ['%12.3f %25.3f %12.3f\n'];
            fprintf(obj.fileID_decoder,obj.printfFormatHeader,'time','K');
            
            
        end
        
        %set BCI starting postion from outside (this info comes from the
        %task controller (usually)
        function obj = set_fixation_position(obj,fixation_position)
            obj.fixation_position  = fixation_position;
        end
        
        
        function pos = get_position(obj)
            pos = [obj.position(obj.sample-obj.delay,1) obj.position(obj.sample-obj.delay,2)];
        end
        
        %This function get called ever iteration and does something after a certain amount of time.
        function obj = loop(obj,task_state,t,interval,spike_data,decoder_on,target_position,p)
            obj.sample = obj.sample +1;
            obj.time(obj.sample) = t;
            %Start to move only after the go cue and if the decoder is on
            if (~isempty(task_state.new_stage) && decoder_on) && (strcmp(task_state.stage_type,'2') || strcmp(task_state.stage_type,'2'))
                obj.time(obj.sample) = t;
                obj.firing_rate(obj.sample,:) = spike_data./interval; %firing rates are stored only when the cursor is supposed to move
%                  if (strcmp(task_state.stage_type,'1') )
%                      obj.P = 0;
%                  end
                obj.UpdateVelocity(target_position,p);
                
                %Stop the cursor when hit the target
            elseif (~isempty(task_state.new_stage) && decoder_on) && strcmp(task_state.stage_type,'3')
                obj.position(obj.sample,:) = obj.position(obj.sample,:) ;
                obj.velocity(obj.sample,:) = [0 0];
                obj.P = 0;
                
                
            else
                % Put cursur at zero position at the beginning of the trial
                % and when BCI is not running
                
                obj.position(obj.sample,:) = obj.fixation_position';%% read from TC 
                obj.velocity(obj.sample,:) = [0 0];
                obj.X_update = [1; obj.position(obj.sample,:)'; obj.velocity(obj.sample,:)'];
                obj.P = 0;
                
            end
            %Send the updated position to the task controller
            
            %obj.send_position();
            
            
        end
        
        %Velocity Kalman Filter function
        function obj = UpdateVelocity(obj,target_position,p)
            %Kalman filter parameters:
            
            obj.Z = obj.firing_rate(obj.sample,find(obj.neurons ==1))'; %the delay takes into account the delay between firing rates and actuation
            obj.X = obj.X_update; %update from previous stage
            obj.X(2:3) = obj.position(obj.sample-obj.delay,:)';
            obj.X(4:5) = obj.velocity(obj.sample-obj.delay,:)';
            
            % I. time update the equations
            obj.X_prior = obj.A*obj.X; %a priori estimate of the state
            obj.P = obj.A*obj.P*obj.A' + obj.W; %error covariance matrix
            
            %We presume that the user internalize the filter's estimate of
            %cursor position  with complete certainty at time t.
%             obj.P (:,1) = 0;
%             obj.P (:,2) = 0;
%             obj.P (3,:) = 0;
%             obj.P (4,:) = 0;
%             obj.P (5,:) = 0;
            
            
            
            % II Measurements update equations
            obj.K = obj.P*obj.H'*inv(obj.H*obj.P*obj.H' + obj.Q);
            obj.X_update = obj.X_prior + obj.K*(obj.Z-obj.H*obj.X_prior);
            
            obj.P = (eye(size(obj.W)) -obj.K*obj.H)*obj.P;
            
            
            
            %dt =0.05;
            obj.velocity(obj.sample,:) = obj.X_update(4:5)';
           obtimal_vector = -obj.position(obj.sample-1,:) +  target_position;
            %obtimal_vector = target_position;
           
            %obj.position(obj.sample,:) = obj.position(obj.sample-1,:) +dt*norm(obj.velocity(obj.sample,:))*(obtimal_vector./norm(obtimal_vector)*p + dt*(1-p)*obj.velocity(obj.sample,:)./norm(obj.velocity(obj.sample,:)));
            obj.position(obj.sample,:) = obj.position(obj.sample-1,:) +obj.dt*norm(obj.velocity(obj.sample,:))*(obtimal_vector./norm(obtimal_vector)*p + (1-p)*obj.velocity(obj.sample,:)./norm(obj.velocity(obj.sample,:)));
            %obj.position(obj.sample,:) = obj.position(obj.sample-1,:) +obj.dt*obj.velocity(obj.sample,:);
            obj.X_update(2:3) = obj.position(obj.sample,:)';
           %  obj.X_update(4:5) = obj.velocity(obj.sample-delay,:)';
            
          % disp([num2str(obj.velocity(obj.sample,1)/1000),'tt', num2str(obj.velocity(obj.sample,2)/1000)])
            
        end
        
        function OnlineCorrelation(obj,task_state,velocity_vector,decoder_on,isIDLE)
            
            %Output the actual decoder performance stor values in two variables and compare them
            %in the future will be better to store indexes and retrieve
            %data from proper variables.
            if(decoder_on && isIDLE) && (strcmp(task_state.stage_type,'2') || strcmp(task_state.stage_type,'2'))
                obj.correlation_counter = obj.correlation_counter +1;
                obj.correlation_velocity(1,obj.correlation_counter) =  velocity_vector(1,1);
                obj.correlation_velocity(2,obj.correlation_counter) =  velocity_vector(2,1);
%                obj.correlation_velocity(3,obj.correlation_counter) =  velocity_vector(3,1);
                
                obj.bci_correlation_velocity(1,obj.correlation_counter) = obj.velocity(obj.sample-obj.delay,1);
                obj.bci_correlation_velocity(2,obj.correlation_counter) = obj.velocity(obj.sample-obj.delay,2);
              %  obj.bci_correlation_velocity(3,obj.correlation_counter) = obj.velocity(obj.sample-obj.delay,3);
                % disp(num2str(vx_bci(obj.correlation_counter)))
                %         if(task_state.new_stage && (strcmp(task_state.stage_type,'ACQUIRE_MEM_TGT')))
                %             internal_hit_counter = internal_hit_counter +1
                %
                %         end
                
                % display correlation values every ten trials
                if(obj.check_correlation || obj.correlation_counter >= obj.max_corr_samples)
                    % check_correlation = false;
                    rx = corr(obj.correlation_velocity(1,1:obj.correlation_counter )', obj.bci_correlation_velocity(1,1:obj.correlation_counter )');
                    ry = corr(obj.correlation_velocity(2,1:obj.correlation_counter )', obj.bci_correlation_velocity(2,1:obj.correlation_counter )');
                    %rz = corr(obj.correlation_velocity(3,1:obj.correlation_counter )', obj.bci_correlation_velocity(3,1:obj.correlation_counter )');
                    
                    disp(['rx: ' num2str(rx) ' ry:' num2str(ry) ])
                    obj.correlation_counter  = 0;
                    obj.check_correlation = false;
                end
                
                
            end
        end
        
        
        %the decoder is saved at the end of the experiment
        function obj = SaveDecoder(obj)
          
            fprintf(obj.fileID_decoder,obj.printfFormatBody,obj.time(obj.sample),2,3); 
        end
        
        %send the cursor position to th etask controller
%         function obj = send_position(obj)
%             
%             vrpn_server('set_position',obj.position(obj.sample-obj.delay,1),obj.position(obj.sample-obj.delay,2),0);
%          %disp([num2str(obj.position(obj.sample-obj.delay,1)/1000),'tt', num2str(obj.position(obj.sample-obj.delay,2)/1000)])
%         end
        
  
        
        %apply rotation to prefer directions of a subset of neurons
        function obj = UpdateRotation(obj,reshaped_correlation,theta,percent)
            %save original calibration matrix only if the first rotation is
            %applied sine sequential rotations can be applied also
            
            if (obj.rotation_counter == 1)
                obj.H_reset =obj.H;
            end
            
            obj.rotation_counter = obj.rotation_counter+1;
            selected_unit_matrix = false(128,6)
            temp_matrix = find(obj.neurons ==1);
            selected_units = sort(randperm(length(obj.H),floor(length(obj.H)/100*percent)))
            temp_matrix = temp_matrix(selected_units');
            selected_unit_matrix(temp_matrix) = 1;
            %matrix of rotation in 3D
            %         rotation_matrix = [unit_vector(1)^2 + (1-unit_vector(1)^2)*cosd(theta), (1 - cosd(theta))*unit_vector(1)*unit_vector(2) - sind(theta)*unit_vector(3), (1 - cosd(theta))*unit_vector(1)*unit_vector(3) + sind(theta)*unit_vector(2);...
            %             (1 - cosd(theta))*unit_vector(2)*unit_vector(1) + sind(theta)*unit_vector(3), unit_vector(2)^2 + (1 - unit_vector(2)^2)*cosd(theta), (1 - cosd(theta))*unit_vector(2)*unit_vector(3) - sind(theta)*unit_vector(1);...
            %             (1 - cosd(theta))*unit_vector(3)*unit_vector(1) - sind(theta)*unit_vector(2), (1 - cosd(theta))*unit_vector(3)*unit_vector(2) + sind(theta)*unit_vector(1), unit_vector(3)^2 + (1 - unit_vector(3)^2)*cosd(theta) ];
            %matrix of rotation in 2D
            
            rotation_matrix = [cosd(theta),-sind(theta); sind(theta), cosd(theta)];
            % obj.H(selected_units,5:7) = obj.H(selected_units,5:7)*rotation_matrix;
            temp = rotation_matrix*obj.H(selected_units,4:5)';
            obj.H(selected_units,4:5) = temp';
            %save the selected units in a perturbation.mat file
            display_rotated_units(0.01, 0.35, .42, .6,reshaped_correlation',obj.neurons',selected_unit_matrix')
        end
        
        function obj = ResetRotation(obj,reshaped_correlation)
        selected_unit_matrix = false(128,6);
            obj.H = obj.H_reset;
            display_rotated_units(0.01, 0.35, .42, .6,reshaped_correlation',obj.neurons',selected_unit_matrix')
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


