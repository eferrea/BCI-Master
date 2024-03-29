cmake_minimum_required(VERSION 3.12.0)
#set include folders for Windows only 
SET(SFML_INCLUDE_PATH D:/LAB/Libraries/SFML-2.5.1-windows-vc12-64-bit/SFML-2.5.1/include) #change to the full path of your SFML include directory
SET(VRPN_INCLUDE_PATH D:/LAB/Libraries/vrpn_07_33/vrpn) #change to the full path of your VRPN include directory
#set library folders for Windows only
SET(SFML_LIBRARY_PATH D:/LAB/Libraries/SFML-2.5.1-windows-vc12-64-bit/SFML-2.5.1/lib) #change to the full path of your SFML lib directory>
SET(VRPN_LIBRARY_PATH D:/LAB/Libraries/vrpn_07_33/vrpn/pc_win32/Debug) #change here to the full path containing vrpn.lib
SET(VRPN_QUAT_LIBRARY_PATH D:/LAB/Libraries/vrpn_07_33/vrpn/quat/pc_win32/Debug) #change here to the full path containing quat.lib
#set DLLs folder for Windows only
SET(SFML_DLL_PATH D:/LAB/Libraries/SFML-2.5.1-windows-vc12-64-bit/SFML-2.5.1/bin/)



project(TrackM)

add_executable(${PROJECT_NAME} main.cpp vrpn_server_class.cpp)



file(GLOB CONF config.txt)


if (WIN32)
    target_include_directories(${PROJECT_NAME} PUBLIC ${SFML_INCLUDE_PATH}  ${VRPN_INCLUDE_PATH})
    
    target_link_libraries(${PROJECT_NAME} PUBLIC ${SFML_LIBRARY_PATH}/sfml-graphics-d.lib ${SFML_LIBRARY_PATH}/sfml-window-d.lib ${SFML_LIBRARY_PATH}/sfml-system-d.lib ${VRPN_LIBRARY_PATH}/vrpn.lib ${VRPN_QUAT_LIBRARY_PATH}/quat.lib)

    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy ${CONF} $<TARGET_FILE_DIR:${PROJECT_NAME}>)

    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD COMMAND ${CMAKE_COMMAND}  -E copy_directory ${SFML_DLL_PATH}  $<TARGET_FILE_DIR:${PROJECT_NAME}>)



endif (WIN32)

if (UNIX)
   
   target_link_libraries(${PROJECT_NAME} PUBLIC sfml-graphics sfml-window sfml-system vrpn quat pthread)
   
   add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy ${CONF} $<TARGET_FILE_DIR:${PROJECT_NAME}>)

endif (UNIX)

#not tested on mac
if(APPLE)
    
    target_include_directories(${PROJECT_NAME} PUBLIC ${SFML_INCLUDE_PATH}  ${VRPN_INCLUDE_PATH})
    
    target_link_libraries(${PROJECT_NAME} PUBLIC ${SFML_LIBRARY_PATH}/sfml-graphics ${SFML_LIBRARY_PATH}/sfml-window ${SFML_LIBRARY_PATH}/sfml-system 

    ${VRPN_LIBRARY_PATH}/vrpn${VRPN_QUAT_LIBRARY_PATH}/quat)
    
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy ${CONF} $<TARGET_FILE_DIR:${PROJECT_NAME}>)

endif (APPLE)