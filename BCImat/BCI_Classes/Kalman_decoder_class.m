% Decoder class for Kalman Filter decoding approach as described in Wu et al., 2006.
% Decoder position is updated only during stage number 2. This value in
% hard coded here but should be ideally placed in the constructor.
% We decided to update the velocity values only during stage 2 as for
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
        function obj = Kalman_decoder_class(BCI_update_time,max_exp_duration,delay,max_corr_samples)
            
            %INPUT
            %BCI_update_time: choose in seconds the rate of the BCI. (0.05 s is suggested).
            %max_exp_duration: maximum expected time of experiment duration in seconds.
            %delay: number of time bins (!!! not ms) of BCI_update_times to shift the neural activty relative to motor output. This can be used in real experiments to make up for delays
            %in transmission of the neural signal through the spinal cord. Phisiological values are in the range of 100-150 ms). For testing purposes use 0 (0 ms no delay)
            %or 1 (1*BCI_update_time ms).
            %max_corr_samples: specify the max number of samples allowed for estimating a correlation during IDLE contol.
            
            obj.expected_total_samples = ceil(max_exp_duration/BCI_update_time);
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
            obj.max_corr_samples = max_corr_samples;
            obj.correlation_velocity = zeros(3,obj.max_corr_samples);
            obj.bci_correlation_velocity = zeros(3,obj.max_corr_samples);
            obj.check_correlation = false;
            obj.dt = BCI_update_time;
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
        %task controller (usually). It is used to place the cursor at the
        %central fixation target when control is not required.
        function obj = set_fixation_position(obj,fixation_position)
            %INPUT:
            %fixation_position: set the position from where always start the movement. It is used to split the stages
            obj.fixation_position  = fixation_position;
        end
        
        %read out the position of the decoded cursor position
        function pos = get_position(obj)
            pos = [obj.position(obj.sample-obj.delay,1) obj.position(obj.sample-obj.delay,2)];
        end
        
        %This function get called every iteration and update the does the
        %decoding depending of the stage. If we are in manual control mode this function does nothing.
        %Please note that the stage is
        %hard coded: movement decoding happens in stage two whereas in
        %stage 1 and 3 the decoder always output a zero velocity and a
        %fixed position
        function obj = loop(obj,task_state,global_time,interval,spike_data,decoder_on,target_position,p)
            %INPUT:
            
            %task_state: name of the state parser class object
            %global_time: time that has passed snce beginning of the experiment
            %interval:represents the time that has passed since the last call of the this function
            %spike_data: matrix of spikes since the last function call
            %decoder_on: 1 if we are in BCI or IDLE mode, 0 if we are in manually controlled trials
            %target_position: indicates the position of the target in the screen. It is used for  shared controlled trials.
            %p: indicates contribution of computer control and brain control. 0 full brain control, 1 full computer control, 0.5 means half control by computer and half by the brain.
            %all values between 0 and 1 are allowed
            
            obj.sample = obj.sample +1;
            obj.time(obj.sample) = global_time;
            %Start to move only after the go cue and if the decoder is on
            if (~isempty(task_state.new_stage) && decoder_on) && (strcmp(task_state.stage_type,'2') || strcmp(task_state.stage_type,'2'))
                obj.time(obj.sample) = global_time;
                obj.firing_rate(obj.sample,:) = spike_data./interval; %firing rates are stored only when the cursor is supposed to move
                obj.update_velocity(target_position,p);
                
                %Stop the cursor when hit the target
            elseif (~isempty(task_state.new_stage) && decoder_on) && strcmp(task_state.stage_type,'3')
                obj.position(obj.sample,:) = obj.position(obj.sample,:) ;
                obj.velocity(obj.sample,:) = [0 0];
                obj.P = 0;
                
            else
                % Put cursor at zero position at the beginning of the trial
                % and when BCI is not running
                
                obj.position(obj.sample,:) = obj.fixation_position';%% read from TC
                obj.velocity(obj.sample,:) = [0 0];
                obj.X_update = [1; obj.position(obj.sample,:)'; obj.velocity(obj.sample,:)'];
                obj.P = 0;
            end
            
        end
        
        %Velocity Kalman Filter estimation. This fuction does the effective
        %decoding implementing the Kalman filter online. It get called
        %inside the decoder loop function during movement.
        function obj = update_velocity(obj,target_position,p)
            
            %target_position: indicates the position of the target in the screen. It is used for  shared controlled trials.
            %p: indicates contribution of computer control and brain control. 0 full brain control, 1 full computer control, 0.5 means half control by computer and half by the brain.
            %all values between 0 and 1 are allowed
            
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
        
        
        %Output the actual decoder performance stor values in two variables and compare them
        %in the future will be better to store indexes and retrieve
        %data from proper variables.
        function online_correlation(obj,task_state,velocity_vector,decoder_on,isIDLE)
            
            %INPUT:
            %task_state: name of the state parser class object
            %velocity_vector: specify velocity of the cursor
            %decoder_on: 1 if we are in BCI or IDLE mode, 0 if we are in manually controlled trials.
            %isIDLE: 1 if open loop decoding.
            
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
        function obj = save_decoder(obj)
            %!!here only K is saved a full list of decoder parameters can be
            %also retrieved offline by using the spikes and the calibrated_values
            fprintf(obj.fileID_decoder,obj.printfFormatBody,obj.time(obj.sample),obj.K);
        end
        
        
        %apply rotation to prefer directions of a subset of neurons
        function obj = update_rotation(obj,reshaped_correlation,theta,percent)
            %INPUT:
            %reshaped_correlation: reshaped matrix of correlation vlues to display image of units with correlation coding the color.
            %theta: specify the amount of rotation of preferred directions (angle in degrees).
            %percent: specify the percentage of units to rotate.
            %save original calibration matrix. Sequential rotations (by pressing the button more than once without stopping the rotation) overwrite the original calibration matrix.
            
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
        %reset apllied rotation
        function obj = reset_rotation(obj,reshaped_correlation)
            
            %INPUT:
            %reshaped_correlation: reshaped matrix of correlation vlues to diplay image of units with correlation coding the color.
            
            selected_unit_matrix = false(128,6);
            obj.H = obj.H_reset;
            display_rotated_units(0.01, 0.35, .42, .6,reshaped_correlation',obj.neurons',selected_unit_matrix')
        end
        
    end % for methods
end %for class


