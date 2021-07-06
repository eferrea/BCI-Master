//
//  vrpn_server_class.h
//  MOROCO
//
//  Created by Pierre Morel on 28/11/2014.
//  Copyright (c) 2014 DPZ. All rights reserved.
//

#ifndef __MOROCO__vrpn_server_class__
#define __MOROCO__vrpn_server_class__

#include <stdio.h>
#include "vrpn_Text.h"
#include "vrpn_Tracker.h"
#include "vrpn_Connection.h"
#include <string>
//#include "eigen3/Eigen/Dense"


class vrpn_server_class : public vrpn_Tracker
{
public:
    vrpn_server_class(std::string name , vrpn_Connection *c);
    virtual ~vrpn_server_class() {};
    virtual void mainloop();
    void set_position(double x, double y, double z);
    //void set_position(Eigen::Vector3d posvec);
    /// Send a text message.
    int send_message(const char *msg,
                     vrpn_TEXT_SEVERITY type = vrpn_TEXT_NORMAL,
                     vrpn_uint32 level = 0,
                     const struct timeval time = vrpn_TEXT_NOW);
    int send_message(const std::string &msg);
protected:
    struct timeval _timestamp;
};




#endif /* defined(__MOROCO__vrpn_server_class__) */
