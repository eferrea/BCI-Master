classdef Kalman_calibrator_class < handle
    properties (Access=private)
        time;
        t_movement;
        t_movement_bci;
        directions;
        dimensions;
        sample;
        position;
        is_movement;
        is_hit;
        start_index;
        stop_index;
        is_movement_and_hit;
        is_movement_and_hit_and_BCI;
        velocity;
        accelleration;
        r_squared;
        load;
        delay;
        sample_bci;
        is_decoder_on;
        expected_total_samples;
        dt;
        A;
        W;
        H;
        Q;
        X;
        X1;
        X2;
        Z;
        Y;
        H_red;
        X_red;
        
    end
    
    properties (Access=public)
        preferred_direction;
        baseline_rate;
        modulation_depth;
        correlation_tuning;
        neurons;
        firing_rate;
        training_sample_number;
        filename;
    end
    
    methods (Access=public)
        
        %Constructor class
        function obj = Kalman_calibrator_class(dimensions, sample_size,max_exp_duration,delay)
            
            obj.delay = delay;
            obj.load = false;
            obj.expected_total_samples = ceil(max_exp_duration/sample_size);
            obj.time = zeros(1, obj.expected_total_samples);
            obj.preferred_direction = zeros(768,3);
            obj.dimensions = dimensions;
            obj.neurons = false(128,6);
            obj.position = zeros(2, obj.expected_total_samples);
            obj.velocity = zeros(2, obj.expected_total_samples);
            obj.firing_rate = zeros(obj.expected_total_samples,768);
            obj.sample = 1;
            obj.is_decoder_on = false(obj.expected_total_samples,1);
            obj.is_movement = false(obj.expected_total_samples,1);
            obj.is_hit = false(obj.expected_total_samples,1);
            obj.is_movement_and_hit = false(obj.expected_total_samples,1);
            obj.is_movement_and_hit_and_BCI = false(obj.expected_total_samples,1);
            obj.dt = sample_size;
            obj.directions = zeros(1000,3);
            obj.correlation_tuning = zeros(1,768);
            obj.H = zeros(768,5);
            obj.filename = 'xxx';
            
        end
        
%         function obj = set_decoder_dynamic()
%             decoder_object.A = A;
%             decoder.object.W = W;
%         end
            
        
        %this is the loop calibrator class to store the values (speeds and firing rates) that will be
        %used for regression depending on conditions. It saves
        %indexes for the movement time.
        function obj = loop(obj,task_state,t,interval,spike_data,position,velocity,decoder_on,decoder_object,target_position,eye_fixation)
            
            if ~isempty(task_state.new_stage)
                %internally store useful values at every iteration
                obj.time(obj.sample) = t; %not used yet but might be useful to save the values of time
                obj.firing_rate(obj.sample,:) = spike_data./interval;
                obj.is_decoder_on(obj.sample) = decoder_on; %used for boolean operations
                
                %if we are in BCI mode positions and velocieties are dictated by the
                %the DECODER
                if(obj.is_decoder_on(obj.sample))
                    obj.position(:,obj.sample) = decoder_object.position(decoder_object.sample,:);
                    %the velocity is the intended one.
                    obtimal_vector = target_position-decoder_object.position(decoder_object.sample-1,:);
                    % obj.velocity (:,obj.sample) = norm(decoder_object.velocity(decoder_object.sample,:))*(decoder_object.velocity(decoder_object.sample,:)/norm(decoder_object.velocity(decoder_object.sample,:)) - target_position);
                    obj.velocity (:,obj.sample) = norm(decoder_object.velocity(decoder_object.sample,:))*obtimal_vector/norm(obtimal_vector);
                else
                    %if we are in manual positions and velocieties are dictated by
                    %the TASK CONTROLLER
                    obj.position(:,obj.sample) = position;
                    obj.velocity (:,obj.sample) = velocity;
                    
                end
                
                
                %three stages calibration
                
                if  ( strcmp(task_state.stage_type,'1') |  strcmp(task_state.stage_type,'2')) ...
                        & (norm(velocity) > 0.2) & (norm(velocity) < 500);
                    
                    obj.is_movement(obj.sample,1)  = true;
                    display(task_state.stage_type)
                    %store the internal timestamp when the movement is supposed to start
                    %  if strcmp(task_state.stage_type,'LEAVE_FIX_MEM') && (task_state.new_stage == 1)
                    if strcmpi(task_state.stage_type,'1') && (task_state.new_stage == 1)
                        obj.start_index = obj.sample;
                    end
                    
                end
                
                
                %if the stage was hit then store the values for regression
                
                % if strcmp(task_state.stage_type(1:6),'REWARD') && (task_state.new_stage == 1)
                if strcmp('3',task_state.stage_type) && (task_state.new_stage == 1)
                    %Store the internal index to know if it was a hit or
                    %not.
                    obj.stop_index = obj.sample;
                    obj.is_hit(obj.start_index:obj.stop_index,1) = true;
                    obj.is_movement_and_hit = obj.is_movement & obj.is_hit & (~obj.is_decoder_on);
                    obj.is_movement_and_hit_and_BCI = obj.is_movement & obj.is_hit & obj.is_decoder_on;
                    
                end
                
                %update internal counter at every iteration
                obj.sample = obj.sample +1;
                
            end
            
        end
        
        % Update Kalman Filter paramaters for decoder (the parameters can
        % be loaded or calculated from manual control or BCI control)
        function obj = UpdateDecoder(obj,decoder_object,decoder_on)
            
            
            
            %Calculate state equation dynamics only from the manual
            %control and set the corresponding decoder matrix and save it
            if (~decoder_on)
                %Build Kalman Filter matrixes for calibration
                obj.X1 = obj.X(:,1:end-1); %it misses last sample
                obj.X2 = obj.X(:,2:end); %it misses first sample
                
                decoder_object.A = obj.X2*obj.X1'*inv(obj.X1*obj.X1'); %dynamical system solution (dampened dynamic)
                
                %We costrain A matrix reflectig Kinematic values
%                   decoder_object.A(:,1) = 0;
%                  decoder_object.A(:,2) = 0;
%                  decoder_object.A(:,5) = 0;
%                  decoder_object.A(5,:) = 0;
%                  decoder_object.A(5,5) = 1;
                 
%                  decoder_object.A(1:2,1:2) = eye(2);
%                  decoder_object.A(1:2,3:4)  = eye(2).*obj.dt;
%                 decoder_object.A(5:7,2:4)  = zeros(2);
                
                %Calculate final Kalman parameters with the selected neurons only
                decoder_object.W = (obj.X2-decoder_object.A*obj.X1)*(obj.X2-decoder_object.A*obj.X1)'./(obj.training_sample_number-1);
                %we constrain the W matrix so that for the dynamic model integrated velocity
                %fully explain position
                
%                  decoder_object.W(:,1:2) = 0;
%                  decoder_object.W(1:2,:) = 0;
%                  decoder_object.W(5,:) = 0;
%                  
%                  decoder_object.A =decoder_object.A';
%                  decoder_object.W = decoder_object.W';
                
            end
            %Select parameters
            obj.Y = obj.Z(find(obj.neurons ==1),:);
            [decoder_object.n_neurons,sample_number] =  size(obj.Y);
            decoder_object.H = zeros(decoder_object.n_neurons,5);
            %             decoder_object.H = obj.Y*obj.X'*inv(obj.X*obj.X'); %linear regression (generative model)
            %             decoder_object.H(:,2:4) = 0; %(velocity only Kalman Filter)
            
            % Do regression only on velocity changes
            obj.X_red = [obj.X(1,:); obj.X(4:5,:)];
            H_new = obj.Y*obj.X_red'/(obj.X_red*obj.X_red'); %linear regression (generative model)
            decoder_object.H(:,1) = H_new(:,1);
            decoder_object.H(:,4:5) =H_new(:,2:3);
            decoder_object.H(:,2:3) = 0; %(velocity only Kalman Filter)
            decoder_object.P = 0; %everytime the decoder is updated, erase the P matrix. (important!!!)
            
            
            
            
            decoder_object.Q = (obj.Y-decoder_object.H*obj.X)*(obj.Y-decoder_object.H*obj.X)'./sample_number;
            decoder_object.neurons = obj.neurons;
            
            
            %   end
            
            obj.SaveCalibration(decoder_object);
        end
        
        function obj = SaveCalibration(obj,decoder_object)
            
            [year,month,day] =  ymd(datetime);
            [hour,minute,second] = hms(datetime);
            filename_root = [num2str(year) '-' num2str(month) '-' num2str(day) '_' num2str(hour) '-'  num2str(minute) '-'  num2str(ceil(second))]
            obj.filename = [filename_root '_calibrated_values.mat']
            %store the values at the end of calibration
            T_stored = obj.correlation_tuning; %save correlation Values
            N_stored = obj.neurons; %save the matrix of used neurons
            Z_stored = obj.Z;%save all firing rates of neurons
            X_stored = obj.X; %save regression parameters
            Y_stored = obj.Y;%save firings of selected neurons
            A_stored =  decoder_object.A;%save dynamical system matrix
            Q_stored = decoder_object.Q;%save firing rates cross-covariance
            W_stored = decoder_object.W;%save dynamical system cross-covariance
            dH_stored = decoder_object.H;
            cH_stored = obj.H;
            time_stored = obj.t_movement;
            samples_stored = obj.training_sample_number;
            
            
            save(obj.filename,'time_stored','X_stored','Y_stored','dH_stored','cH_stored','A_stored','Q_stored','W_stored','N_stored','Z_stored','T_stored','samples_stored');
            
        end
        
        % Update Kalman Filter calibrator paramaters during manual control
        function obj = UpdateRegression(obj,decoder_on)
         
            % obj.load = false;
            
            if (decoder_on)
                
                pos = obj.position(:,obj.is_movement_and_hit_and_BCI);
                
                vel = obj.velocity(:,obj.is_movement_and_hit_and_BCI);
                
                %                 norm_of_vel = arrayfun(@(fix) norm(vel(:,fix)), 1:size(vel,2));
                %               norm_vel = vel./repmat(norm_of_vel,3,1);
                
                % obj.X = [];
                %obj.Z = [];
                
                obj.X = [ones(sum(obj.is_movement_and_hit_and_BCI),1)'; pos; vel];
                
                
                %Firing rate matrix
                %obj.Z = obj.firing_rate(repmat(obj.is_movement_and_hit,1,768)); %this commando take some time try to optimize it
                obj.Z = obj.firing_rate(obj.is_movement_and_hit_and_BCI,:);
                obj.t_movement = obj.time(obj.is_movement_and_hit_and_BCI);
                disp('BCI Regression')
            else
                
                pos = obj.position(:,obj.is_movement_and_hit);
                
                vel = obj.velocity(:,obj.is_movement_and_hit);
                
                %                 aaa = ones(3,length(find(obj.is_movement_and_hit==1)));
                %
                %                 norm_of_vel = arrayfun(@(fix) norm(vel(:,fix)), 1:size(vel,2));
                %                 norm_vel = vel./repmat(norm_of_vel,3,1);
                
                %Build State matrix with first row set to one to take
                %into account baseline firing rate in regression
                %obj.X = [ones(sum(obj.is_movement_and_hit),1)'; pos; vel];
                
                %obj.X = [];
                %obj.Z = [];
                obj.X = [ones(sum(obj.is_movement_and_hit),1)'; pos; vel];
                
                
                
                obj.Z = obj.firing_rate(obj.is_movement_and_hit,:);
                obj.t_movement = obj.time(obj.is_movement_and_hit);
                disp('Manual Control Regression')
            end
            obj.Z = obj.Z';
            [n_neurons,obj.training_sample_number] =  size(obj.Z);
            
            clear H_new
            if obj.training_sample_number > obj.delay
                %Calculate matrix of coefficients
                obj.X_red = [obj.X(1,:); obj.X(4:5,:)];
                %obj.H = obj.Z*obj.X'*inv(obj.X*obj.X'); %linear regression (generative model)
                %H_new_1 = obj.Z(:,1:end-obj.delay)*obj.X_red(:,1+obj.delay:end)'/(obj.X_red(:,1+obj.delay:end)*obj.X_red(:,1+obj.delay:end)'); %linear regression (generative model)
                %H_new = obj.X_red(:,1+obj.delay:end)'\obj.Z(:,1:end-obj.delay)';
                H_new = obj.Z(:,1:end-obj.delay)/obj.X_red(:,1+obj.delay:end);
                 %H_new =  H_new';
                obj.H(:,1) = H_new(:,1);
                obj.H(:,4:5) = H_new(:,2:3);
                %obj.H(:,2:4) = 0; %(velocity only Kalman Filter)
                
                
                
                % Explicit other relevant parameters for tuning.
                obj.baseline_rate = obj.H(:,1);
                
                %Calculate modulation depth as norm of the theta matrix
                %(if the velocity vector for training was normalized)
                %(check for this)
                obj.modulation_depth = arrayfun(@(fix) norm(obj.H(fix,4:end)), 1:size(obj.H,1));
                % obj.modulation_depth = arrayfun(@(fix) norm(obj.H(fix,2:end)), 1:size(obj.H,1));
                
                %Calculate preferred directions as the third and second
                %elements of B normalized by theta(2:end) length.
                %(check for this as weel)
                
                obj.preferred_direction = (obj.H(:,4:end)./repmat(obj.modulation_depth',1,2))';
                % obj.preferred_direction = (obj.H(:,2:end)./repmat(obj.modulation_depth',1,3))';
                
                %Calculate regression coefficient
                residuals = obj.Z - obj.H*obj.X;
                SSresiduals = sum(residuals.^2,2);
                SStotal = (obj.training_sample_number-1) * var(obj.Z');
                obj.correlation_tuning = 1 - SSresiduals./SStotal';
                %Find how many samples were used for regression
                %sample_number = obj.training_sample_number;
                
                %  sample_number
                
            end
        end
        
        %this function load and set the decoder parameters (it might be unused in future)
        function obj = LoadDecoder(obj,decoder_object)
            
            uiopen('.mat')
            %obj.load = true;
            %Load calibrator parameters
            obj.neurons = N_stored;
            obj.H = cH_stored;
            
            % Explicit other relevant parameters for tuning.
            obj.baseline_rate = obj.H(:,1);
            
            %Calculate modulation depth as norm of the theta matrix
            %(if the velocity vector for training was normalized)
            %(check for this)
            obj.modulation_depth = arrayfun(@(fix) norm(cH_stored(fix,4:end)), 1:size(cH_stored,1));
            
            %Calculate preferred directions as the third and second
            %elements of B normalized by theta(2:end) length.
            %(check for this as well)
            
            obj.preferred_direction = (cH_stored(:,4:end)./repmat(obj.modulation_depth',1,2))';
            
            obj.correlation_tuning = T_stored;
            obj.training_sample_number = samples_stored;
            %set decoder parameters
            decoder_object.H = dH_stored;
            decoder_object.A = A_stored;
            decoder_object.Q = Q_stored;
            decoder_object.W = W_stored;
            decoder_object.neurons = N_stored;
            
            
        end
        function ResetCalibrator(obj)
            
            obj.time = zeros(1, obj.expected_total_samples);
            obj.preferred_direction = zeros(768,3);  
            obj.neurons = false(128,6);
            obj.position = zeros(3, obj.expected_total_samples);
            obj.velocity = zeros(3, obj.expected_total_samples);
            obj.firing_rate = zeros(obj.expected_total_samples,768);
            obj.sample = 1;
            obj.is_decoder_on = false(obj.expected_total_samples,1);
            obj.is_movement = false(obj.expected_total_samples,1);
            obj.is_hit = false(obj.expected_total_samples,1);
            obj.is_movement_and_hit = false(obj.expected_total_samples,1);
            obj.is_movement_and_hit_and_BCI = false(obj.expected_total_samples,1);
            obj.directions = zeros(1000,3);
            obj.correlation_tuning = zeros(1,768);
            
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
        
        
        
    end % end of methods
    
end %end of class