%This class handles messages coming from the task controller , many of
%the parameters listed below are not used with the basic provided task
%controller but were used during our experiments. We kept in the class function that handles messages coming from the eye tracker.
% @ P.Morel, 2015

classdef Task_state_class < handle
    
    
    properties
        stage_type
        new_stage
        trial_index
        trial_index_TC
        trial_type
        new_trial
        parameters
        history
        new_trial_callback
        iseye
    end
    
    methods
        %constructor Initialize
        function obj= Task_state_class()
            obj.trial_index=0;
            obj.history={};
            obj.new_trial_callback=@(tmp)disp('new_trial'); %define call back function
            obj.parameters.REFERENCE_X_DIRECTION = nan; %target x position
            obj.parameters.REFERENCE_Y_DIRECTION = nan; %target y position
            obj.parameters.REFERENCE_Z_DIRECTION = nan; %target z position
            obj.parameters.X_FIXATION = 0; %eye fix x position
            obj.parameters.Y_FIXATION = 0; %eye fix y position
            obj.iseye = []; %to store if an eye tracker is used
            obj.trial_index_TC = 0; %initialize counter for number of trial
            
        end
        
        function set_new_trial_callback(obj,fun)
            
            %INPUT: 
            
            %fun: callback function name (defined in constructor), it simply displays when a new trial starts
            obj.new_trial_callback=fun;
        end
 
        %it parses the message from VRPN       
        function parse_messages(obj,msgs)
            
            %INPUT: 
            
            %msgs: vrpn text messages to be parsed inside BCImat
            
            obj.new_stage=false;
            obj.new_trial=false;
            
            for k=1:length(msgs)
                
                C=textscan(msgs{k},'%s','Delimiter',',');
                
                
                if numel(C{:})==2
                    
                    %Look if we are at trial start
                    if strcmp(C{1}{1},'TRIAL')
                        obj.new_trial_callback(obj);
                        obj.new_trial=true;
                        obj.trial_type=C{1}{2};
                        obj.trial_index=obj.trial_index+1;
                        continue;
                    end
                    
                    %Look if it is a eye fixation trial
                    if strcmp(C{1}{1},'ISEYE')
                        obj.iseye=C{1}{2};
                        
                        continue
                    end
                    
                    %Get the trial index from TC
                    if strcmp(C{1}{1},'TRIAL_NUMBER')
                        obj.trial_index_TC=str2num(C{1}{2});
                        
                        continue;
                    end
                    
                    %Look if we are at trial start
                    if strcmp(C{1}{1},'STAGE')
                        obj.new_stage=true;
                        obj.stage_type=C{1}{2};
                        continue;
                    end
                    
                    if ~isempty(str2num(C{1}{2}))
                        obj.parameters.(C{1}{1})=str2num(C{1}{2});
                        if isfield(obj.history,C{1}{1}) && obj.trial_index>0
                            obj.history.(C{1}{1})(obj.trial_index)=str2num(C{1}{2});
                        else
                            obj.history.(C{1}{1})=nan(1000,1);
                        end
                    else
                        obj.parameters.(C{1}{1})=C{1}{2};
                        if isfield(obj.history,C{1}{1}) && obj.trial_index>0
                            obj.history.(C{1}{1}){obj.trial_index}=C{1}{2};
                        else
                            obj.history.(C{1}{1})=repmat({'NA'},1000,1);
                        end
                    end
                    
                end
                
                
            end
        end
        
    end
    
end

