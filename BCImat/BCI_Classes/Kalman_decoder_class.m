% Decoder class for Kalman Filter decoding approach as described in Wu et al., 2006.
% Decoder position is updated only during stage number 2. This value in
% hard coded here but should be ideally placed in the constructor.
% We decided to update the velocity values only during stage 2 (line 128 in loop function) as for
% some standard BCI control experiments.

%@E.Ferrea, 2015

classdef Kalman_decoder_class < handle;
    properties (Access=private)
        
        
        K;
        iteration_step;
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
        function obj = Kalman_decoder_class(sample_size,max_exp_duration,delay,max_samples)
            
            obj.expected_total_samples = ceil(max_exp_duration/sample_size);
            obj.K = 0;
            obj.position = zeros(obj.expected_total_samples,2);
            obj.velocity = zeros(obj.expected_total_samples,2);
            obj.preferred_direction = zeros(768,2);
            obj.baseline_rate = zeros(1,768);
            obj.modulation_depth = ones(1,768);
            obj.iteration_step = 0;
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
            obj.printfFormatBody = ['%12.3f  %12.3f\n'];
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
        
        %This function get called every iteration and update the does the
        %decoding depending of the stage. Please note that the stage is
        %hard coded: movement decoding happens in stage two whereas in
        %stage 1 and 3 the decoder always output a zero velocity and a
        %fixed position
        function obj = loop(obj,task_state,t,interval,spike_data,decoder_on,target_position,p)
            obj.sample = obj.sample +1;
            obj.time(obj.sample) = t;
            %Start to move only after the go cue and if the decoder is on
            if (~isempty(task_state.new_stage) && decoder_on) && (strcmp(task_state.stage_type,'2') || strcmp(task_state.stage_type,'2'))
                obj.time(obj.sample) = t;
                obj.firing_rate(obj.sample,:) = spike_data./interval; %firing rates are stored only when the cursor is supposed to move
                obj.update_velocity(target_position,p);
                
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
        function obj = update_velocity(obj,target_position,p)
            %Kalman filter parameters:
            
            obj.Z = obj.firing_rate(obj.sample,find(obj.neurons ==1))'; %the delay takes into account the delay between firing rates and actuation
            obj.X = obj.X_update; %update from previous stage
            obj.X(2:3) = obj.position(obj.sample-obj.delay,:)';
            obj.X(4:5) = obj.velocity(obj.sample-obj.delay,:)';
            
            % I. time update the equations
            obj.X_prior = obj.A*obj.X; %a priori estimate of the state
            obj.P = obj.A*obj.P*obj.A' + obj.W; %error covariance matrix
            
            
            
            % II Measurements update equations
            obj.K = obj.P*obj.H'*inv(obj.H*obj.P*obj.H' + obj.Q);
            obj.X_update = obj.X_prior + obj.K*(obj.Z-obj.H*obj.X_prior);
            
            obj.P = (eye(size(obj.W)) -obj.K*obj.H)*obj.P;
            
            obj.velocity(obj.sample,:) = obj.X_update(4:5)';
            obtimal_vector = -obj.position(obj.sample-1,:) +  target_position;
            
            obj.position(obj.sample,:) = obj.position(obj.sample-1,:) +obj.dt*norm(obj.velocity(obj.sample,:))*(obtimal_vector./norm(obtimal_vector)*p + (1-p)*obj.velocity(obj.sample,:)./norm(obj.velocity(obj.sample,:)));
            obj.X_update(2:3) = obj.position(obj.sample,:)';
            
            
        end
        
        function online_correlation(obj,task_state,velocity_vector,decoder_on,isIDLE)
            
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
            %!!here only K is saved a full list of decoder parameters can be
            %also retrieved offline by using the spikes and the calibrated_values
            fprintf(obj.fileID_decoder,obj.printfFormatBody,obj.time(obj.sample),obj.K);
        end
        
        
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
        
    end % for methods
end %for class


