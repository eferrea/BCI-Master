%% windows
%mex server
mex -ID:\LAB\Libraries\vrpn_07_33\vrpn -LD:\LAB\Libraries\vrpn_07_33\vrpn\pc_win32\Debug vrpn_server.cpp vrpn.lib
%mex client
mex -ID:\LAB\Libraries\vrpn_07_33\vrpn -LD:\LAB\Libraries\vrpn_07_33\vrpn\pc_win32\Debug vrpn_client.cpp vrpn.lib

%% mac
%mex client
mex -I/usr/local/Cellar/vrpn/07.33/include ...
    -L/usr/local/Cellar/vrpn/07.33/lib vrpn_client.cpp libvrpn.a
%mex server
mex -I/usr/local/Cellar/vrpn/07.33/include ...
    -L/usr/local/Cellar/vrpn/07.33/lib vrpn_server.cpp libvrpn.a
