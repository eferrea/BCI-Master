classdef calibrator_class < handle
    properties (Access=private)
        t_start_hold;
        t_start_movement;
        hit_counter;
        all_firings;
        directions;
        dimensions;
        
    end
    
    properties (Access=public)
        preferred_direction;
        baseline_rate;
        modulation_depth;
        correlation_tuning;
        neurons;
    end
    
    methods (Access=public)
        
        %Constructor class
        function obj = calibrator_class(dimensions)
            obj.preferred_direction = zeros(768,3);
            obj.dimensions = dimensions;
            obj.all_firings = zeros(1000,768);
            obj.t_start_hold = 0;
            obj.t_start_movement = 0;
            obj.hit_counter = 0;
            obj.all_firings = zeros(1000,768);
            
            if obj.dimensions == 2
                obj.directions = zeros(1000);
            else
                obj.directions = zeros(1000,3);
                obj.correlation_tuning = zeros(1,768);
                
            end
            
        end
        
        %this is the main calibrator class
        function obj = loop(obj,task_state,t,spike_data)
            
            if ~isempty(task_state.new_stage)
                %Check whether the movement started
                if (task_state.new_stage == 1) && strcmp(task_state.stage_type,'PRE_ACQUIRE_MEM_TGT')
                    
                    %Store the time when th movement start, let's try to use matlab time
                    obj.t_start_movement = t(end);
                    % obj.display(obj.t_start_movement);
                    
                end
                
            end
            
            if ~isempty(task_state.new_stage)
                %Check whether the movement end
                if (task_state.new_stage == 1) && strcmp(task_state.stage_type,'HOLD_MEM_TGT')
                    
                    %Store the time when the movement end,let's try to use matlab time
                    obj.t_start_hold = t(end);
                    %   obj.display(obj.t_start_hold);
                end
                
                
                %If we are at the end of a trial we look if it was a hit or
                %not(hopefully the spike buffer did not get yet refreshed)
                if strcmp(task_state.stage_type,'REWARD')&& (task_state.new_stage)
                    
                    
                    %update the hit counter
                    obj.hit_counter = obj.hit_counter + 1;
                    
                    %select proper spikes between t_start_hold
                    % +  a interval in s
                    interval = [ obj.t_start_hold obj.t_start_hold + 0.3]; %!!!! be sure to specified the lenght of this interval in [sec] (to be changed)
                    % aa = [size(t); size(spike_data)]
                    % choose the proper spikes in the buffer corresponding to the
                    % interval and calculate MFR for each unit
                    firing_rate = (spike_data(find(t < interval(2),1,'last'),:) - spike_data(find(t > interval(1),1,'first'),:))./(interval(2)-interval(1));
                    %group the firing rate for successful trials
                    % sizes = [size( obj.all_firings); size(firing_rate)]
                    obj.all_firings(obj.hit_counter,:) = firing_rate;
                    
                    if obj.dimensions == 2
                        %group all the directions for successful trials
                        obj.directions(obj.hit_counter) = task_state.parameters.REFERENCE_DIRECTION;
                        [C, ia, ic] = unique(obj.directions(1:obj.hit_counter));
                    else
                        obj.directions(obj.hit_counter,1) = task_state.parameters.REFERENCE_X_DIRECTION;
                        obj.directions(obj.hit_counter,2) = task_state.parameters.REFERENCE_Y_DIRECTION;
                        obj.directions(obj.hit_counter,3) = task_state.parameters.REFERENCE_Z_DIRECTION;
                        [C, ia, ic] = unique(obj.directions(1:obj.hit_counter,:),'rows');
                    end
                    
                    %accumulate data with the same direction of movement and
                    %do the average
                    
                    
                 %   de_selection = obj.all_firings(1:obj.hit_counter,1:n_units);
                 de_selection = obj.all_firings(1:obj.hit_counter,:);
                    [c, r] = meshgrid(1:size(de_selection, 2), ic);
                    MFR = (accumarray([r(:), c(:)], de_selection(:), [], @mean));
                    % obj.display(C);
                    %   pause()
                    %Linearly regress every neuron and direction
                    
                    theta = zeros(obj.dimensions+1,768);
                    if obj.dimensions == 2
                        X = [ones(length(C),1) cosd(C)' sind(C)'];
                    else
                        [rows columns] = size(C);
                       
                        X = [ones(rows,1) C(:,1) C(:,2) C(:,3)]
                        %X = X(~isnan(X))
                    end
                    
                    
                    %   theta = zeros(4,n_units);
                    
                    % display(MFR)
                    for n = 1 : 768;%n_units
                        
                        Y = MFR(:,n);
                        
                        %Use normal equation solution
                        theta(:,n) = inv(X'*X)*X'*Y;
                      %  theta(:,n) = (X'*X)\X'*Y;
                        
                       obj.correlation_tuning(1,n) = corr(Y,(theta(:,n)'*X')');
                        
                        %obj.correlation_tuning(mod(n,128),ceil(n/128)) = corr(Y,(theta(:,n)'*X')');
                       % obj.plotTuning(correlation(n,1))
                        %Use gradient descent
                        %Use matlab linear regression function
%                         figure(2)
%                         imagesc(correlation);
%                         colorbar
                    end
                    
                    % display(Y)
                    % Calculate baseline Firing rates as first element of theta
                    obj.baseline_rate = theta(1,:);
                    %Calculate modulation depth as norm of the theta matrix (without baseline_rate)
                    obj.modulation_depth = arrayfun(@(fix) norm(theta(2:end,fix)), 1:size(theta,2));
                    %Calculate preferred directions as the third and second
                    %elements of theta normalized by theta(2:end) length.
                    if obj.dimensions == 2
                        obj.preferred_direction = (theta(2:end,:)./repmat(obj.modulation_depth,2,1))';
                    else
                        obj.preferred_direction = (theta(2:end,:)./repmat(obj.modulation_depth,3,1))';
                    end
                    
                    
                    
                end
            end
        end
        %update decoder parameters
        function obj = update_decoder(obj,decoder_object,poisson_object)
            %just for testing algorithm
%             decoder_object.preferred_direction = poisson_object.True_PD';
%             decoder_object.baseline_rate = poisson_object.Baseline_rate;
%             decoder_object.modulation_depth = poisson_object.MD;
       
             decoder_object.preferred_direction = obj.preferred_direction;
             decoder_object.baseline_rate = obj.baseline_rate;
             decoder_object.modulation_depth = obj.modulation_depth;
            
        end
        
       
        
    end
    
end