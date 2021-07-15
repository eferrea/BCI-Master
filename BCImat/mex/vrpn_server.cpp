// Mex glue for VRPN trakcer server (+ability to send text)
#include "mex.h"
#include <stdio.h>
#include <string.h>


//#include <tchar.h>
#include <math.h>
#include <time.h>
#include "vrpn_Text.h"
#include "vrpn_Tracker.h"
#include "vrpn_Connection.h"
#include <mutex>  

#include<iostream>

extern void _main();

/////////////////////// TRACKER /////////////////////////////

// your tracker class must inherit from the vrpn_Tracker class
class myTracker : public vrpn_Tracker
{
public:
    myTracker(std::string name , vrpn_Connection *c);
    virtual ~myTracker() {};
    virtual void mainloop();
    void set_position(double x, double y, double z);
    	/// Send a text message.
	int send_message(const char *msg, 
			    vrpn_TEXT_SEVERITY type = vrpn_TEXT_NORMAL,
			    vrpn_uint32 level = 0,
			    const struct timeval time = vrpn_TEXT_NOW);
protected:
    struct timeval _timestamp;
};




myTracker::myTracker( std::string name , vrpn_Connection *c ):vrpn_Tracker( name.c_str(), c )
{
    mexPrintf("Created tracker\n");
}

//set position and update both tracker and connection
void myTracker::set_position(double x, double y, double z) {
    
    pos[0] = x;
    pos[1] = y;
    pos[2] = z;
    this->mainloop();
    this->connectionPtr()->mainloop(); //Here we retrieve the connection used by this tracker and update it
}

int myTracker::send_message(const char *msg, 				  
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
  
  send_text_message(msg, now, type, level);
  this->mainloop();
  this->connectionPtr()->mainloop(); //Here we retrieve the connection used by this tracker and update it
  
  
  return 1;
}

void myTracker::mainloop()
{
    
    vrpn_gettimeofday(&_timestamp, NULL);
    vrpn_Tracker::timestamp = _timestamp;
    char msgbuf[1000];
    d_sensor = 0;
    
    int  len = vrpn_Tracker::encode_to(msgbuf);
    if (d_connection->pack_message(len, _timestamp, position_m_id, d_sender_id, msgbuf,vrpn_CONNECTION_LOW_LATENCY))
    {
        mexPrintf("can't write message: tossing %g\n",stderr);
    }
    
    
    //vrpn_SleepMsecs(3);
    server_mainloop();
    
    
}


void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[]) {
    
    //By using static here these guys will be kept in memory between mex calls
    static vrpn_Connection* m_Connection;
    static myTracker* serverTracker;
    
    char *cmd;
    double    *vin1, *vin2, *vin3, *vin4;
    
    if (mxIsChar(prhs[0])){
        /*  check for proper number of arguments */
        
        /* get command from first input */
        cmd = mxArrayToString(prhs[0]);
        
        // if command is "start_server", start the server
        if (!strcmp(cmd,"start_server"))
        {
            
            if(nrhs!=2)
                mexErrMsgTxt("Server initialization takes one additional argument");
            
            /* make sure tracker was not started using "mex locked" state */
            if (mexIsLocked())
                mexErrMsgTxt("Server already initialized.");
            
            /* lock mex so that no-one accidentally clears function */
            mexLock();
            
            size_t buflen = mxGetN(prhs[1])*sizeof(mxChar)+1;
            char *buf;
            buf = (char*) mxMalloc(buflen);
            
            /* Copy the string data into buf. */
            int status = mxGetString(prhs[1], buf, (mwSize)buflen);
            
            
            //Create connection and tracker
           m_Connection = new vrpn_Connection_IP();
            //m_Connection = vrpn_create_server_connection(buf);
            serverTracker = new myTracker(buf,m_Connection);
            
            mexPrintf("Server created:  %s\n", buf);
            
        }
        /*Delete tracker*/
        else if (!strcmp(cmd,"stop_server"))
        {
            
            if(nrhs!=1)
                mexErrMsgTxt("Server stopping takes no additional arguments");
            
            
            /* make sure that the thread was started using "mex locked" status*/
            if (!mexIsLocked())
                mexErrMsgTxt("Tracker not initialized yet."); /*This function will return control to MATLAB*/
            
            //Clean up memory
            delete(serverTracker);
            delete(m_Connection);
            
            mexUnlock();
            
            mexPrintf("Server Closed\n");
            
        }
        else if (!strcmp(cmd,"set_position"))
        {
            
            //Update position
            if (nrhs != 4) {
                mexErrMsgIdAndTxt("MATLAB:mexcpp:nargin",
                        "set_position requires three additional arguments");
            } else if (nlhs >= 1) {
                mexErrMsgIdAndTxt("MATLAB:mexcpp:nargout",
                        "MEXCPP requires no output argument.");
            }
            
            //We have to check that the tracker is initialized otherwise the pointers are empty and the MEX crashes
            if (!mexIsLocked())
                mexErrMsgTxt("Server is not initialized yet.");
            
            //Get data
            vin1 = (double *) mxGetPr(prhs[1]);
            vin2 = (double *) mxGetPr(prhs[2]);
            vin3 = (double *) mxGetPr(prhs[3]);
            
            //Ask for server update
            serverTracker->set_position(*vin1, *vin2, *vin3);
            
            
        }
        else if (!strcmp(cmd,"send_message"))
        {
            if (nrhs !=2)
               mexErrMsgIdAndTxt("MATLAB:mexcpp:nargin",
                        "send_message requires one additional arguments");
            
            //We have to check that the tracker is initialized otherwise the pointers are empty and the MEX crashes 
            if (!mexIsLocked())
                mexErrMsgTxt("Server is not initialized yet.");
            
            
            size_t buflen = mxGetN(prhs[1])*sizeof(mxChar)+1;
            char *buf;
            buf = (char*) mxMalloc(buflen);
            
            /* Copy the string data into buf. */
            int status = mxGetString(prhs[1], buf, (mwSize)buflen);
            //mexPrintf("Sent string:  %s\n", buf);
            
            
            serverTracker->send_message(buf,vrpn_TEXT_NORMAL,0,vrpn_TEXT_NOW); //vrpn_TEXT_NORMAL vrpn_TEXT_ERROR vrpn_TEXT_WARNING 
            
            /* When finished using the string, deallocate it. */
            mxFree(buf);
            
            
            
        }
        
    }
    else
    {
        mexErrMsgTxt("First argument must be a string");

    }
}