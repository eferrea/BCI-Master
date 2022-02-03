% Calibrator class for Kalman Filter decoding approach as described in Wu et
% al., 2006 and implementing retraining approach as described in Gilja et al., 2012.
% Note that the stages for calibration are hard coded in this class in the
% loop function (line 116).Only trial that are successful are used for calibration (see line 134). The name of the calibration stage (or stages) can be ideally
%placed in the constructor. In this example stage 1 and 2 are used for callibration and data are stored only if stage 3 is reached (indicating a sucessfull trial).
%@E.Ferrea, 2015


classdef Kalman_calibrator_class < handle
    properties (Access=private)
        time;
        t_movement;
        t_movement_bci;
        directions;
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
        
        %Constructor
        function obj = Kalman_calibrator_class(sample_size,max_exp_duration,delay)
            
            obj.delay = delay;
            obj.load = false;
            obj.expected_total_samples = ceil(max_exp_duration/sample_size);
            obj.time = zeros(1, obj.expected_total_samples);
            obj.preferred_direction = zeros(768,3);
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
        
        %this is the loop calibrator class to store the values (speeds and firing rates) that will be
        %used for regression depending on conditions. It saves
        %indexes for the movement time.
        function obj = loop(obj,task_state,t,interval,spike_data,position,velocity,decoder_on,decoder_object,target_position)
            
            if ~isempty(task_state.new_stage)
                %internally store useful values at every iteration
                obj.time(obj.sample) = t; %not used yet but might be useful to save the values of time
                obj.firing_rate(obj.sample,:) = spike_data./interval;
                obj.is_decoder_on(obj.sample) = decoder_on; %used for boolean operations
                
                %if we are in BCI mode positions and velocities are dictated by the
                %the DECODER
                if(obj.is_decoder_on(obj.sample))
                    obj.position(:,obj.sample) = decoder_object.position(decoder_object.sample,:);
                    %the velocity is the intended one.
                    obtimal_vector = target_position-decoder_object.position(decoder_object.sample-1,:);
                    obj.velocity (:,obj.sample) = norm(decoder_object.velocity(decoder_object.sample,:))*obtimal_vector/norm(obtimal_vector);
                else
                    %if we are in manual positions and velocieties are dictated by
                    %the TASK CONTROLLER
                    obj.position(:,obj.sample) = position;
                    obj.velocity (:,obj.sample) = velocity;
                    
                end
                
                
                %two stages calibration. We use stages 1 and 2 to regress
                %firing rates and velocities. Ideally the stages should be
                %specified in the class constructor
                
                if  ( strcmp(task_state.stage_type,'1') |  strcmp(task_state.stage_type,'2')) ...
                        & (norm(velocity) > 0.2) & (norm(velocity) < 500);
                    
                    obj.is_movement(obj.sample,1)  = true;
                    display(['stage:',task_state.stage_type])
                    %display(['sampling', num2str(rand(1,1))])
                    %store the internal timestamp when the movement is
                    %supposed to start
                    if strcmpi(task_state.stage_type,'1') && (task_state.new_stage == 1)
                        obj.start_index = obj.sample;
                    end
                    
                end
                
                
                % if the stage was hit then store the values for
                % regression: stage 3 in this case indicate successfull
                % movement so we store firing rate and velocities.
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
        function obj = update_decoder(obj,decoder_object,decoder_on)
            
            
            
            %Calculate state equation dynamics only from the manual
            %control and set the corresponding decoder matrix and save it
            if (~decoder_on)
                %Build Kalman Filter matrixes for calibration
                obj.X1 = obj.X(:,1:end-1); %it misses last sample
                obj.X2 = obj.X(:,2:end); %it misses first sample
                
                decoder_object.A = obj.X2*obj.X1'*inv(obj.X1*obj.X1'); %dynamical system solution (dampened dynamic)
                
                %We costrain A matrix reflectig Kinematic values
                %Calculate final Kalman parameters with the selected neurons only
                decoder_object.W = (obj.X2-decoder_object.A*obj.X1)*(obj.X2-decoder_object.A*obj.X1)'./(obj.training_sample_number-1);
                
                
            end
            %Select parameters
            obj.Y = obj.Z(find(obj.neurons ==1),:);
            [decoder_object.n_neurons,sample_number] =  size(obj.Y);
            decoder_object.H = zeros(decoder_object.n_neurons,5);
            
            
            % Do regression only on velocity changes
            obj.X_red = [obj.X(1,:); obj.X(4:5,:)];
            H_new = obj.Y*obj.X_red'/(obj.X_red*obj.X_red'); %linear regression (generative model)
            decoder_object.H(:,1) = H_new(:,1);
            decoder_object.H(:,4:5) =H_new(:,2:3);
            decoder_object.H(:,2:3) = 0; %(velocity only Kalman Filter)
            decoder_object.P = 0; %everytime the decoder is updated, erase the P matrix. (important!!!)
            
            
            
            decoder_object.Q = (obj.Y-decoder_object.H*obj.X)*(obj.Y-decoder_object.H*obj.X)'./sample_number;
            decoder_object.neurons = obj.neurons;
            
            
            obj.save_calibration(decoder_object);
        end
        
        function obj = save_calibration(obj,decoder_object)
            
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
        function obj = update_regression(obj,decoder_on)
            
            % obj.load = false;
            
            if (decoder_on)
                
                pos = obj.position(:,obj.is_movement_and_hit_and_BCI);
                
                vel = obj.velocity(:,obj.is_movement_and_hit_and_BCI);
                
                obj.X = [ones(sum(obj.is_movement_and_hit_and_BCI),1)'; pos; vel];
                
                
                %Firing rate matrix
                %obj.Z = obj.firing_rate(repmat(obj.is_movement_and_hit,1,768)); %this commando take some time try to optimize it
                obj.Z = obj.firing_rate(obj.is_movement_and_hit_and_BCI,:);
                obj.t_movement = obj.time(obj.is_movement_and_hit_and_BCI);
                disp('BCI Regression')
            else
                
                pos = obj.position(:,obj.is_movement_and_hit);
                
                vel = obj.velocity(:,obj.is_movement_and_hit);
                
                
                %Construct State matrix with first row set to one to take
                %into account baseline firing rate in regression
                
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
                H_new = obj.Z(:,1:end-obj.delay)/obj.X_red(:,1+obj.delay:end);
                obj.H(:,1) = H_new(:,1);
                obj.H(:,4:5) = H_new(:,2:3);
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
                
                %Calculate regression coefficient
                residuals = obj.Z - obj.H*obj.X;
                SSresiduals = sum(residuals.^2,2);
                SStotal = (obj.training_sample_number-1) * var(obj.Z');
                obj.correlation_tuning = 1 - SSresiduals./SStotal';
                
            end
        end
        
        %this function load and set the decoder parameters (it might be unused in future)
        function obj = load_decoder(obj,decoder_object)
            
            uiopen('.mat')
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
        function reset_calibrator(obj)
            
            obj.time = zeros(1, obj.expected_total_samples);
            obj.preferred_direction = zeros(768,3);
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