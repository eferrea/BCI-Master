%% 

mex('CXX="clang++"',...
      'MACOSX_DEPLOYMENT_TARGET="10.9"',...
      'CXXLIBS="-lc++"',...
      'CXXFLAGS="-std=c++11"',...
      '-lvrpn',...
      '-L/usr/local/lib',...
      'ServerThread.cpp')
  
  %% M 
  ServerThread('Init')
  %% 
  for k=1:1000
    ServerThread(sin(k/100)/10,0);
    pause(0.001)
  end
  %% 
  ServerThread('Finish')
  
  %% New version doesn't need threads and doesn't leak memory
  
   munlock vrpn_client 
   munlock vrpn_server
   clear vrpn_client
   clear vrpn_server
   clear mex
  [~,mexLoaded] = inmem('-completenames')
  
  mex('CXX="clang++"',...
      'MACOSX_DEPLOYMENT_TARGET="10.9"',...
      'CXXLIBS="-lc++"',...
      'CXXFLAGS="-std=c++11"',...
      '-lvrpn',...
      '-L/usr/local/lib',...
      '-g',...
      'vrpn_server.cpp')
  
  
    mex('CXX="clang++"',...
      'MACOSX_DEPLOYMENT_TARGET="10.9"',...
      'CXXLIBS="-lc++"',...
      'CXXFLAGS="-std=c++11"',...
      '-lvrpn',...
      '-L/usr/local/lib',...
      '-g',...
      'vrpn_client.cpp')
  
  %%
  
  dbmex on
  
  %%

    vrpn_server('start_server','Tracker0@127.0.0.1')
    
   % vrpn_client('open_connection','Tracker10@127.0.0.1:6666')
   vrpn_client('open_connection','Tracker0@127.0.0.1')
    

    
  %% 
  k=0
while 1
    %vrpn_server('set_position',sin(k/100)/10,cos(k/100)/10,k);
 
    vrpn_server('set_position',-1,-1,k);
    if mod(k,10)==0
        vrpn_server('send_message',['test ' num2str(k)]);
    end
    
    
    if mod(k,20)==0
        vrpn_client('get_positions','Tracker0@127.0.0.1')
      % vrpn_client('get_positions','Tracker10@127.0.0.1:6666')
    end
    
    if mod(k,20)==0
        vrpn_client('get_messages','Tracker0@127.0.0.1')
       % vrpn_client('get_messages','Tracker10@127.0.0.1:6666')
    end
    
    pause(0.01)
    k=k+1;
  end
  
  %%
  
  while 1
      a=vrpn_client('get_positions','Tracker10@127.0.0.1:6666');
      b=vrpn_client('get_messages','Tracker10@127.0.0.1:6666');
      if ~isempty(a)
          a
          b
      end
      pause(0.1)
  end
  
    %%
    
    tp=task_state_class()
    in_movement=false;
    figure
    hold on;
    
    
  while 1
      a=vrpn_client('get_positions','Tracker10@127.0.0.1:6666');
      [b,t]=vrpn_client('get_messages','Tracker10@127.0.0.1:6666');
      
      if ~isempty(a)
          if in_movement 
            plot(a(:,1),a(:,2),'r.')
          else
              plot(a(:,1),a(:,2),'b.','MarkerSize',1)
          end
      end
      
      if ~isempty(b)
          tp.parse_messages(b);

          if (tp.new_trial==1)
              if isfield(tp.parameters,'REFERENCE_DIRECTION')
                subplot(2,2,tp.parameters.REFERENCE_DIRECTION/90+1);
                hold on
              end
          end
          
          if (tp.new_stage==1) && (strcmp(tp.stage_type,'PRE_ACQUIRE_MEM_TGT'));
              disp(['MOVEMENT PERIOD START'])
              in_movement=true;
          end
          
         if (tp.new_stage==1) && (strcmp(tp.stage_type,'HOLD_MEM_TGT') || strcmp(tp.stage_type,'ERROR') && in_movement);
              disp(['MOVEMENT PERIOD END'])
              in_movement=false;
          end
          
      end
      xlim([-200 200])
      ylim([-200 200])
    pause(0.1)
    drawnow
  end
  
  
%%


vrpn_server('stop_server')
vrpn_client('close_connection','Tracker0@127.0.0.1:5555')
vrpn_client('close_connection','Tracker10@127.0.0.1:6666')
  
  
  %% Version with a stop button for the loop
  
fh=figure('Position',[500 500 400 300]);
h = uicontrol('Style', 'PushButton', 'String', 'Stop BCI', ...
              'Callback', 'delete(gcbo)','Position',[100 100 200 100]);
          
vrpn_server('start_server')
k=1;

while ishandle(h)
    vrpn_server('set_position',sin(k/100)/10,cos(k/100)/10,k);
    k=k+1;
    pause(0.001);
end

vrpn_server('stop_server')
if ishandle(fh)
    close(fh)
end
  
  
  