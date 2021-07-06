//
//  vrpn_server_class.cpp
//  MOROCO
//
//  Created by Pierre Morel on 28/11/2014.
//  Copyright (c) 2014 DPZ. All rights reserved.
//

#include "vrpn_server_class.h"
#include <chrono>
#include <thread>


/////////////////////// TRACKER /////////////////////////////

// your tracker class must inherit from the vrpn_Tracker class



vrpn_server_class::vrpn_server_class( std::string name , vrpn_Connection *c ):vrpn_Tracker( name.c_str(), c )
{
    printf("Created tracker\n");
}

//set position and update both tracker and connection
void vrpn_server_class::set_position(double x, double y, double z) {
    
    pos[0] = x;
    pos[1] = y;
    pos[2] = z;
    this->mainloop();
    this->connectionPtr()->mainloop(); //Here we retrieve the connection used by this tracker and update it
}

/*void vrpn_server_class::set_position(Eigen::Vector3d posvec)
{
    pos[0] = posvec(0);
    pos[1] = posvec(1);
    pos[2] = posvec(2);
    this->mainloop();
    this->connectionPtr()->mainloop(); //Here we retrieve the connection used by this tracker and update it
}*/

int vrpn_server_class::send_message(const char *msg,
                            vrpn_TEXT_SEVERITY type,
                            vrpn_uint32 level,
                            const struct timeval time)
{
    struct timeval now;
    
    // Replace the time value with the current time if the user passed in the
    // constant time referring to "now".
    if ( (time.tv_sec == vrpn_TEXT_NOW.tv_sec) && (time.tv_usec == vrpn_TEXT_NOW.tv_usec) ) {
        vrpn_gettimeofday(&now, NULL);
    } else {
        now = time;
    }
    // send message, time, type and level
    return send_text_message(msg, now, type, level);
}

int vrpn_server_class::send_message(const std::string &msg)
{
    return send_message(msg.c_str(),vrpn_TEXT_NORMAL,0,vrpn_TEXT_NOW);
}

void vrpn_server_class::mainloop()
{
    vrpn_gettimeofday(&_timestamp, NULL);
    vrpn_Tracker::timestamp = _timestamp;
    char msgbuf[1000];
    d_sensor = 0;
    int  len = vrpn_Tracker::encode_to(msgbuf);
    if (d_connection->pack_message(len, _timestamp, position_m_id, d_sender_id, msgbuf,vrpn_CONNECTION_LOW_LATENCY))
    {
        printf("can't write message: tossing\n");
    }

	//printf("%d, %d, %d\n", pos[0],pos[1], pos[2]);
	std::this_thread::sleep_for(std::chrono::microseconds(2000));
    server_mainloop();
}


