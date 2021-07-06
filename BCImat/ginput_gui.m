function varargout = ginput_gui(varargin)
%GINPUT_GUI GINPUT on GUI (Keeping all toolbar features on), use of custom
%   pointers for different plots and more.
%   [PT1, PT2] = GINPUT_GUI(I1,N1,I2,N2) inputs two image data matrices I1
%   and I2 and the number of selection points N1 and N2 to be clicked on
%   their plots respectively. PT1 and PT2 are two cells of coordinate
%   points clicked on the plots of I1 and I2 respectively.
%
%   This is basically a GUI framework, inviting users to tweak it to their
%   needs. It comes with the following salient features:
% 1.Shows different Pointers when mouse is hovered over one or more
%   than one plots. The number of plots used in this framework is two, 
%   but it can be easily extended to more numbers if needed.
% 2.Point clicking on the plots can be associated to custom functions and
%   thus they can be used to act as region selection, image data finding,
%   image coordinate finding, etc. In one of my previous projects I
%   extended this GUI framework to make it able to display multiple
%   rectangular boxes on a single plot, change the Pointer whenever mouse
%   was hovered over one of these boxes, click one of these and display the
%   data from the selected rectangular box onto another plot. So thats
%   possible too if anyone is interested.
% 3.X and Y coordinates of the points clicked are obtainable as GUI
%   output. Thus, it can also be used to act as GINPUT, while keeping the
%   commonly used figure toolbar features on and letting user activate any
%   GUI component. When GINPUT is called, user needs to complete the point
%   selection before proceeding with any other instruction. During the
%   point selection with GINPUT, the GUI toolbar features like Zoom-in,
%   Zoom-out, Pan and few others get disabled. This limitation
%   doesnt exist in this code, as inherently it simulates GINPUT for point
%   selection only, but lets user proceed with the next instruction or
%   other functions. This GINPUT-style point selection is also continuous,
%   meaning user wont need to activate it with any GUI component, but of
%   course its start and stop is controllable. The figure toolbar
%   features that are available with this GUI are - New Figure, Open File,
%   Print Figure, Zoom In, Zoom Out, Pan, Rotate 3D, Data Cursor, Insert
%   Colorbar & Insert Legend.
% 4.With minor tweaking, its possible to modify this framework to make it
%   act as IMPIXEL, but use commonly used figure toolbar features as well,
%   unlike in IMPIXEL. This can be found on MATLAB Central too.
%
%   Class Support
%   -------------
%   Input:
%       Input1: The image data for plot1 and thus it could be uint8,
%       uint16, int16, double, single or logical.
%       Input2: The number of points to be selected on the image for plot1.
%       Leave it as empty, if the GUI is to be closed with double click on
%       plot1. This is a scalar double or empty.
%       Input3: The image data for plot2 and thus it could be uint8,
%       uint16, int16, double, single or logical.
%       Input4: The number of points to be selected on the image for plot2.
%       This is a scalar double or empty.
%
%   Output:
%       Output1(Optional): The XY coordinate points clicked by the user on
%       plot1. This is of class double and size Mx2, where M could be any
%       non-negative integer.
%       Output2(Optional): The XY coordinate points clicked by the user on
%       plot2. This is of class double and size Nx2, where N could be any
%       non-negative integer.
%
%   Example
%   -------
%     img1 = imread('peppers.png');
%     img2 = imread('gantrycrane.png');
%     [pt1cell,pt2cell] = ginput_gui(img1,[],img2,[]);
%     pt1 = cell2mat(pt1cell)
%     pt2 = cell2mat(pt2cell)
%
%   Motivation: During one of my previous projects, I had one GUI with many
%   plots and requiring data to be plotted in each one of them. In one of
%   the scenarios on the GUI, I had four plots and it was needed to select
%   a region from one axes of plot1 and plot the selected region onto axes
%   of plot2 using GINPUT style of selection. The selection was needed to
%   be continuous throughout the entire run of the GUI. Thus, I was
%   required to not use a GUI component to initiate the selection process.
%   This basically made the in-built MATLAB function GINPUT useless.
%       I looked up for help on Mathworks Forum and other places, but could
%   not find anything close to my possible solution. But somewhere I read
%   about using BUTTONDOWNFCN and it worked for me.
%       Necessity is the mother of invention right?
%       The code in the associated m-file is a stripped out simple version
%   of my project GUI. I hope this will help most of the users who are in
%   similar situation as I was in before.
%
%   Future:
%   As an author of this GUI, I would love to see more figure window
%   toolbar features being adapted into it. Also, if someone is interested
%   to control the plotting features more, like putting title or x and y
%   limits, those are possible too. In fact, in my original code, I had
%   control over the x and y limits, but threw away that in this code to
%   keep it simple. But if you are interested, let me know. This would
%   require tweaking only the image showing portion of the associated
%   m-file.
%
%   Feedback / Bugs / How-this-helped / How-this-sucked /
%   How-this-could_be_improved / Anything about it are MOST welcome.
%
%   See also GINPUT.
%
%   Platform: MATLAB R2011B
%
%   Divakar Roy   2012

warning off;

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @ginput_gui_OpeningFcn, ...
    'gui_OutputFcn',  @ginput_gui_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before ginput_gui is made visible.
function ginput_gui_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
handles.input = varargin;
% Update handles structure
guidata(hObject, handles);

global data_struct

data_struct.gui_ready = false;
%% Backstory: data_struct.gui_ready was added at the last moment, as in
%% cases where the mouse was moved around during the GUI loading, it was
%% seen executing the function - detect_mouse_hover, even before the plots
%% were plotted and the error msg reported was that handles.uipanel1 wasn't
%% found, suggesting that it was executing the section1 of function
%% ginput_gui_OutputFcn.

return;

% --- Outputs from this function are returned to the command line.
function varargout = ginput_gui_OutputFcn(hObject, eventdata, handles)

global data_struct

%% 1. IF AXES IS PARENTED BY UIPANEL, XLABEL AND YLABELS WON'T BE SHOWN.
%% FOR THIS REASON, WE ARE REQUIRED TO DEASSCOCIATE THIS CHILD-PARENT
%% RELATIONSHIP. THIS IS DONE BY REMOVING THE ALREADY EXISTING UIPANEL AND
%% PUTTING A NEW ONE AT THE SAME POSITION. THIS STEP COULD BE AVOIDED, IF
%% DURING THE GUI CREATION, THE AXES IS CREATED BEFORE THE UIPANEL CREATION.

if isequal(get(handles.uipanel1,'Children'),handles.axes1)
    set(handles.axes1,'Parent',gcf);
    uipanel_orgpos = get(handles.uipanel1,'Position');
    set(handles.axes1,'Position',uipanel_orgpos);
    delete(handles.uipanel1);
    handles.uipanel1 = uipanel('Title','','FontSize',12,'BackgroundColor','white','Position',uipanel_orgpos);
end

if isequal(get(handles.uipanel2,'Children'),handles.axes2)
    set(handles.axes2,'Parent',gcf);
    uipanel_orgpos = get(handles.uipanel2,'Position');
    set(handles.axes2,'Position',uipanel_orgpos);
    delete(handles.uipanel2);
    handles.uipanel2 = uipanel('Title','','FontSize',12,'BackgroundColor','white','Position',uipanel_orgpos);
end

%% 2. INITIAL GUI SETUP
%% Get the inputs and store with the declared global variable
data_struct.input = handles.input;

%% Control the GUI components with data
data_struct.handles = handles;

%% Status of Buttons on toolbar settings
data_struct.pressed_tool1=0;
data_struct.pressed_tool2=0;
data_struct.pressed_tool3=0;
data_struct.pressed_tool4=0;
data_struct.pressed_tool5=0;

%% Save original pointer type to be used in mouse hovering
data_struct.original_pointer_type = get(gcf,'Pointer');

%% 3. INITIAL SETUP FOR ALL PLOTS
%% Store the clicked points
data_struct.plot1_points_clicked = [];
data_struct.plot2_points_clicked = [];

%% 3.1. INITIAL SETUP FOR PLOT1
%% 3.1.1. Setup number of selection points and data
data_struct.plot1_figure_data = cell2mat(data_struct.input(1));

data_struct.plot1_num_points = cell2mat(data_struct.input(2));
if isempty(data_struct.plot1_num_points)
    data_struct.plot1_num_points = Inf;
end

%% 3.1.2. Get the x and y ranges, so that proper ginput-type mouse pointer could be shown on the image section of the figure window.
data_struct.plot1_xrange = [1 size(data_struct.plot1_figure_data,2)];
data_struct.plot1_yrange = [1 size(data_struct.plot1_figure_data,1)];

%% 3.1.3. Plot Data
set(data_struct.handles.uipanel1,'Visible','off');
axes(data_struct.handles.axes1);
imagesc(data_struct.plot1_xrange,data_struct.plot1_yrange,data_struct.plot1_figure_data);
xlabel('Width','fontsize',10,'fontweight','bold')
ylabel('Height','fontsize',10,'fontweight','bold')

%% 4. INITIAL SETUP FOR PLOT2
%% 4.1. Setup number of selection points and data
data_struct.plot2_figure_data = cell2mat(data_struct.input(3));

data_struct.plot2_num_points = cell2mat(data_struct.input(4));
if isempty(data_struct.plot2_num_points)
    data_struct.plot2_num_points = Inf;
end

%% 4.2. Get the x and y ranges, so that proper ginput-type mouse pointer could be shown on the image section of the figure window.
data_struct.plot2_xrange = [1 size(data_struct.plot2_figure_data,2)];
data_struct.plot2_yrange = [1 size(data_struct.plot2_figure_data,1)];

%% 4.3. Plot Data
set(data_struct.handles.uipanel2,'Visible','off');
axes(data_struct.handles.axes2);
imagesc(data_struct.plot2_xrange,data_struct.plot2_yrange,data_struct.plot2_figure_data);
xlabel('Width','fontsize',10,'fontweight','bold')
ylabel('Height','fontsize',10,'fontweight','bold')

data_struct.gui_ready = true;

%% 5. Initial setup is done. After this point on, the mouse pointer will change based on the axes and
%% their uipanels and also point selection will get activated
%% 5.1. Start Mouse Hovering Detection
set(gcf,'WindowButtonMotionFcn',@detect_mouse_hover);

%% 5.2. To be used till the mouse has been clicked for the number of points to be clicked for
uiwait(gcf);

%% 5.3. Outout the X-Y data
varargout{1} = {data_struct.plot1_points_clicked};
varargout{2} = {data_struct.plot2_points_clicked};

return;

function detect_mouse_hover(handles,object, eventdata)

global data_struct

if ~data_struct.gui_ready
    return;
end

if data_struct.pressed_tool1==1 || data_struct.pressed_tool2==1 || data_struct.pressed_tool3==1 || data_struct.pressed_tool4==1 || data_struct.pressed_tool5==1
    return;
end

estimate_new_position(data_struct.handles.uipanel1,'uipanel1');
estimate_new_position(data_struct.handles.uipanel2,'uipanel2');

cp = get(gcf,'CurrentPoint');
cpa = get(gca,'CurrentPoint');

edup = data_struct.uipanel_estimated_position.uipanel1;
cond1_plot1 = cp(1,1)>edup(1) && cp(1,1)<edup(1)+edup(3) && cp(1,2)>edup(2) && cp(1,2)<edup(2)+edup(4);
cond2_plot1 = cpa(1,1)>data_struct.plot1_xrange(1) && cpa(1,1)<data_struct.plot1_xrange(2) && cpa(1,2)>data_struct.plot1_yrange(1) && cpa(1,2)<data_struct.plot1_yrange(2);

edup = data_struct.uipanel_estimated_position.uipanel2;
cond1_plot2 = cp(1,1)>edup(1) && cp(1,1)<edup(1)+edup(3) && cp(1,2)>edup(2) && cp(1,2)<edup(2)+edup(4);
cond2_plot2 = cpa(1,1)>data_struct.plot2_xrange(1) && cpa(1,1)<data_struct.plot2_xrange(2) && cpa(1,2)>data_struct.plot2_yrange(1) && cpa(1,2)<data_struct.plot2_yrange(2);

if cond1_plot1
    axes(data_struct.handles.axes1);
    if cond2_plot1
        set(gcf,'Pointer','cross');
        set(gcf,'WindowButtonDownFcn',@detect_mouse_press_print_plus);
    end
elseif cond1_plot2
    axes(data_struct.handles.axes2);
    if cond2_plot2
        set(gcf,'Pointer','crosshair');
        set(gcf,'WindowButtonDownFcn',@detect_mouse_press_print_plus);
    end
else
    set(gcf,'Pointer',data_struct.original_pointer_type);
    % If doing nothing, you need to tell it to do nothing, or else the other condition for 'WindowButtonDownFcn' will be exceuted from the
    % previous mouse position and that is not desirable
    set(gcf,'WindowButtonDownFcn',@detect_mouse_press_do_nothing);
end

return;

function detect_mouse_press_print_plus(handles,object, eventdata)

global data_struct

cp = get(gca,'CurrentPoint');
%% Print a plus on the clicked point, to be used as an indicator
handle_text = text(cp(1,1),cp(1,2),'+','FontSize',10,'FontWeight','bold');

if gca==data_struct.handles.axes1
    data_struct.plot1_points_clicked = [data_struct.plot1_points_clicked ; [cp(1,1) cp(1,2)]];
else
    data_struct.plot2_points_clicked = [data_struct.plot2_points_clicked ; [cp(1,1) cp(1,2)]];
end

%% Procedures to close the GUI [Edit this section depending on the requirements of closing the GUI] OR If the user wants not to close the GUI, he may just remove this section.
%% 1. Check for number of selections and compare with the number mentioned as the input
if size(data_struct.plot1_points_clicked,1)~=data_struct.plot1_num_points % Not enough points clicked yet or is empty.
    data_struct.first_point_handle = handle_text;
else   % Enough points have been clicked.
    if isfield(data_struct,'first_point_handle')
        delete(data_struct.first_point_handle);
    end
    delete(gcf);
end

%% 2. Code when the user wants to end the point selection by double clicking on the image
if size(data_struct.plot1_points_clicked,1)>1 && isempty(cell2mat(data_struct.handles.input(2)))
    if data_struct.plot1_points_clicked(end-1,:) == data_struct.plot1_points_clicked(end,:)
        data_struct.plot1_points_clicked(end,:)=[];
        delete(gcf);
    end
end

return;

function detect_mouse_press_do_nothing(handles,object, eventdata)
return;

function estimate_new_position(h1,handle_string)
%% This function is used to get the new position of the uipanel, to be used for GUIs that are Resizable.

global data_struct

gui_position_org = get(gcf,'Position');
uipanel_position_org = get(h1,'Position');

est_pos(1) = gui_position_org(3)*uipanel_position_org(1);
est_pos(2) = gui_position_org(4)*uipanel_position_org(2);
est_pos(3) = gui_position_org(3)*uipanel_position_org(3);
est_pos(4) = gui_position_org(4)*uipanel_position_org(4);

data_struct.uipanel_estimated_position.(handle_string) = est_pos;
return;

%% Figure tools that are not enabled with ginput and therefore cause problem with 'Mouse Press Down' and 'Mouse Pointer Movement'
%% are to be tracked for pressed on or off and based on these statuses, the mouse hovering has to be decided.
function uitoggletool1_OffCallback(hObject, eventdata, handles)
global data_struct
data_struct.pressed_tool1=0;
return;

function uitoggletool1_OnCallback(hObject, eventdata, handles)
global data_struct
data_struct.pressed_tool1=1;
return;

function uitoggletool2_OffCallback(hObject, eventdata, handles)
global data_struct
data_struct.pressed_tool2=0;
return;

function uitoggletool2_OnCallback(hObject, eventdata, handles)
global data_struct
data_struct.pressed_tool2=1;
return;

function uitoggletool3_OffCallback(hObject, eventdata, handles)
global data_struct
data_struct.pressed_tool3=0;
return;

function uitoggletool3_OnCallback(hObject, eventdata, handles)
global data_struct
data_struct.pressed_tool3=1;
%set(gcf,'Pointer','hand');
return;

function uitoggletool4_OffCallback(hObject, eventdata, handles)
global data_struct
data_struct.pressed_tool4=0;
return;

function uitoggletool4_OnCallback(hObject, eventdata, handles)
global data_struct
data_struct.pressed_tool4=1;
return;

function uitoggletool5_OffCallback(hObject, eventdata, handles)
global data_struct
data_struct.pressed_tool5=0;
return;

function uitoggletool5_OnCallback(hObject, eventdata, handles)
global data_struct
data_struct.pressed_tool5=1;
return;