// Mex glue for VRPN trakcer server (+ability to send text)
#include "mex.h"
#include <stdio.h>
#include <string.h>


//#include <tchar.h>
#include <math.h>
#include <time.h>
#include <vector>
#include <unordered_map>
#include <utility>
#include "vrpn_Text.h"
#include "vrpn_Tracker.h"
#include "vrpn_Connection.h"

#include<iostream>

extern void _main();

void VRPN_CALLBACK handle_tracker(void* userData, const vrpn_TRACKERCB t )
{
    //This function is a static member of the class, as such, it has no implicit this pointer to the current object.
    //We pass the this pointer to the function explicitely, and access non-static member variables and function of the class using this pointer (through dereferencing (*pointer). or pointer-> )
    //vrpn_interface_multiple* thisinterface= (vrpn_interface_multiple*) userData;
    
    std::vector<std::vector<double>> *buff=static_cast<std::vector<std::vector<double>> *>(userData);
    
    std::vector<double> temp;
    
    temp.resize(5);
    temp[0]=t.msg_time.tv_sec;
    temp[1]=t.msg_time.tv_usec;
    temp[2]=t.pos[0];
    temp[3]=t.pos[1];
    temp[4]=t.pos[2];
    
    buff->push_back(temp);
    
    //mexPrintf("%i %i %f\n",t.msg_time.tv_sec,t.msg_time.tv_usec,t.pos[2]);
    
}


void VRPN_CALLBACK handle_message(void *userData, const vrpn_TEXTCB info)
{
    //std::vector<std::string> *buff=static_cast<std::vector<std::string> *> (userData);
    
    std::vector<std::pair<std::string,double>> *buff=static_cast<std::vector<std::pair<std::string,double>> *> (userData);
            
    //mexPrintf("message received %s\n",info.message);
    
    //buff->push_back(info.message);
    
    buff->push_back(std::make_pair(info.message,(double)info.msg_time.tv_sec+(double)info.msg_time.tv_usec/1000000.0));
    
}


void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[]) {
    
    //By using static here these guys will be kept in memory between mex calls
    
    
    static std::unordered_map<std::string,vrpn_Tracker_Remote*> vrpnTracker;
    static std::unordered_map<std::string,vrpn_Text_Receiver*> vrpnText;
    static std::unordered_map<std::string,std::vector<std::vector<double>>> position_buffer;
    //static std::unordered_map<std::string,std::vector<std::string>> message_buffer;
    
    static std::unordered_map<std::string,std::vector<std::pair<std::string,double>>> message_buffer;
    static double ref_time=0;
    
    char *cmd,*buf;
    double    *vin1, *vin2, *vin3, *vin4;
    
    
//     size_t buflen = mxGetN(prhs[1])*sizeof(mxChar)+1;
//     char *buf;
//     buf = (char*) mxMalloc(buflen);
//     /* Copy the string data into buf. */
//     int status = mxGetString(prhs[1], buf, (mwSize)buflen);
    
    
    if ((mxIsChar(prhs[0])) && (mxIsChar(prhs[1])))
    {
        /*  check for proper number of arguments */
        
        /* get command from first input */
        cmd = mxArrayToString(prhs[0]);
        buf= mxArrayToString(prhs[1]);
        
        // if command is "start_server", start the server
        if (!strcmp(cmd,"open_connection"))
        {
            
            if(nrhs!=2)
                mexErrMsgTxt("Server initialization one additional argument");
            
            
            /* lock mex so that no-one accidentally clears function */
            if (vrpnTracker.size()==0)
            {
                mexLock();
                mexPrintf("Mex locked\n");
            }
            
            
            //Create connection and tracker
            if (vrpnTracker.count(buf)==0)
            {
                vrpnTracker[buf] = new vrpn_Tracker_Remote(buf);
                vrpnText[buf] = new vrpn_Text_Receiver(buf);
                
                // Register callbacks
                vrpnTracker[buf]->register_change_handler(&position_buffer[buf], handle_tracker);
                vrpnText[buf]->register_message_handler(&message_buffer[buf], handle_message);
                mexPrintf("Connected to :  %s\n", buf);
            }
            else
            {
                mexPrintf("%s already open\n", buf);
            }
            
        }
        /*Delete tracker*/
        else if (!strcmp(cmd,"close_connection"))
        {
            
//             if(nrhs!=2)
//                 mexErrMsgTxt("client stopping takes no additional arguments");
            
            /* make sure that the thread was started using "mex locked" status*/
            if (!mexIsLocked())
                mexErrMsgTxt("Client not initialized yet."); /*This function will return control to MATLAB*/
            
            if (vrpnTracker.count(buf)==1)
            {
                //Clean up memory
                delete vrpnTracker[buf];
                delete vrpnText[buf];
                vrpnTracker.erase(buf);
                vrpnText.erase(buf);
                position_buffer.erase(buf);
                message_buffer.erase(buf);
                mexPrintf("%s closed\n", buf);
            }
            else
            {
                mexPrintf("%s not opened\n", buf);
            }
            if (vrpnTracker.size()==0)
            {
                mexPrintf("All connections closed, mex unlocked\n");
                mexUnlock();
            }
            
        }
        else if (!strcmp(cmd,"get_positions"))
        {
            if (vrpnTracker.count(buf)==1)
            {
                vrpnTracker[buf]->mainloop();
                
                plhs[0] = mxCreateDoubleMatrix((mwSize) position_buffer[buf].size(),(mwSize) 3,mxREAL );
                plhs[1] = mxCreateDoubleMatrix((mwSize) position_buffer[buf].size(),(mwSize) 1,mxREAL );
                
                //Get C array for output matrix
                double *out_array= mxGetPr(plhs[0]);
                double *out_array_t= mxGetPr(plhs[1]);
                
                
                for (int k=0;k<position_buffer[buf].size();k++)
                {
                    out_array[k]=position_buffer[buf][k][2];
                    out_array[k+position_buffer[buf].size()]=position_buffer[buf][k][3];
                    out_array[k+position_buffer[buf].size()*2]=position_buffer[buf][k][4];
                    
          /*          if (ref_time==0)
                    {
                        ref_time=(double)position_buffer[buf][0]+(double)position_buffer[buf][1]/1000000.0;
                    }    
                    out_array_t[k]=(double)position_buffer[buf][0]+(double)position_buffer[buf][1]/1000000.0-ref_time;*/
                    
                }
                position_buffer[buf].clear();
            }
            else
            {
                mexPrintf("%s not opened\n", buf);
            }
        }
        else if (!strcmp(cmd,"get_messages"))
        {
            if (vrpnTracker.count(buf)==1)
            {
                vrpnText[buf]->mainloop();
                
                
                plhs[0]=mxCreateCellMatrix((mwSize) message_buffer[buf].size(),1);
                plhs[1] = mxCreateDoubleMatrix((mwSize) message_buffer[buf].size(),(mwSize) 1,mxREAL );
                
                double *out_array= mxGetPr(plhs[1]);
                
                //mexPrintf("N message %i\n",message_buffer.size());
                
                for (int k=0;k<message_buffer[buf].size();k++)
                {
                    //mexPrintf("message %s\n",message_buffer[k].c_str());
                    mxArray *tmp = mxCreateString(std::get<0>(message_buffer[buf][k]).c_str());
                    mxSetCell(plhs[0],k,tmp);
                    if (ref_time==0)
                    {
                        ref_time=std::get<1>(message_buffer[buf][k]);
                    }    
                    out_array[k]=std::get<1>(message_buffer[buf][k])-ref_time;
                }
                
                message_buffer[buf].clear();
            }
            else
            {
                mexPrintf("%s not opened\n", buf);
            }
        }
        
    }
    else
    {
        mexErrMsgTxt("First argument must be a string");
        
    }
}