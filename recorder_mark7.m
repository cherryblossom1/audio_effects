function varargout = recorder_mark7(varargin)
% RECORDER_MARK7 MATLAB code for recorder_mark7.fig
%      RECORDER_MARK7, by itself, creates a new RECORDER_MARK7 or raises the existing
%      singleton*.
%
%      H = RECORDER_MARK7 returns the handle to a new RECORDER_MARK7 or the handle to
%      the existing singleton*.
%
%      RECORDER_MARK7('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RECORDER_MARK7.M with the given input arguments.
%
%      RECORDER_MARK7('Property','Value',...) creates a new RECORDER_MARK7 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before recorder_mark7_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to recorder_mark7_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%

% Last Modified by GUIDE v2.5 11-Oct-2019 12:54:37

     % Begin initialization code - DO NOT EDIT
     gui_Singleton = 1;
     gui_State = struct('gui_Name',       mfilename, ...
                        'gui_Singleton',  gui_Singleton, ...
                        'gui_OpeningFcn', @recorder_mark7_OpeningFcn, ...
                        'gui_OutputFcn',  @recorder_mark7_OutputFcn, ...
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
end

% ---------------------------------------------------------initialisation------------------------------------------------------------- %
function recorder_mark7_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% varargin   command line arguments to recorder_mark7 (see VARARGIN)
     
     clc;
     % initialise all variables %
     handles = VPinitialise(handles);
     
     % object creation %
     handles.userdata.I = audiorecorder(handles.userdata.Fs,handles.userdata.NBIT,handles.userdata.NCHANS);

     % setting object properties %
     set(handles.userdata.I,...
          'TimerFcn',@(I,~)plotG(handles.userdata.I,...
               [handles.axes6, handles.axes7],...
               handles.userdata.T,...
               handles.userdata.Fs,...
               handles.userdata.filterbank,...
               handles.userdata.fn),...
          'TimerPeriod',handles.userdata.T);
     
     % Choose default command line output for recorder_mark7
     handles.output = hObject;
     
     % Update handles structure
     guidata(hObject, handles);
end
% UIWAIT makes recorder_mark7 wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = recorder_mark7_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
     varargout{1} = handles.output;
end
% ------------------------------------------------------------------------------------------------------------------------------------ %

% -------------------initialise variables and plots----------------------------- %
function x=VPinitialise(handles)
     % initialise all variables %
     handles.userdata.Fs=11025;                % sampling frequency
     handles.userdata.NBIT=16;                % #bits
     handles.userdata.NCHANS=2;               % #channels
     handles.userdata.T=0.08;                 % time frame(block) in seconds
     F0=554;                  % fundamental frequency (A4)
     gr=2^(1/12);             % harmony golden ratio
     key=(0:88)';
     handles.userdata.fn = F0 * gr.^(key-49);
     Ts = 1/handles.userdata.Fs;
     n = (0:Ts:handles.userdata.T)';
     handles.userdata.filterbank = cos(2*pi*n*handles.userdata.fn');
     handles.echo.flag=0;
     handles.reverb.flag=0;
     handles.userdata.data=0;
     handles.userdata.data_write=0;
     
     % initialise filters and plots %
     Fstop = str2double(get(handles.noise.Fstop,'String'));
     Gain = str2double(get(handles.noise.gain,'String'));
     [handles.noise.b, handles.noise.a] = cheby2(12,80,2*Fstop/handles.userdata.Fs);
     handles.noise.b = handles.noise.b*Gain;
     [H,W] = freqz(Gain*handles.noise.b,handles.noise.a,512,handles.userdata.Fs);
     axes(handles.axes3);
     plot(W,20*log10(abs(H))); grid on;
     
     N = str2double(get(handles.echo.N,'String'));
     R = str2double(get(handles.echo.R,'String'));
     alpha = str2double(get(handles.echo.alpha,'String'));
     beta = str2double(get(handles.echo.beta,'String'));
     handles.echo.b = [1; zeros(N*R-1,1); -alpha^N];
     handles.echo.a = [1; zeros(R-1,1); -beta];
     [h,t] = impz(handles.echo.b,handles.echo.a);
     axes(handles.axes4);
     stem(t,h); grid on;
     
     R = str2double(get(handles.reverb.R,'String'));
     alpha = str2double(get(handles.reverb.alpha,'String'));
     handles.reverb.b = [alpha; zeros(R-1,1); 1];
     handles.reverb.a = [1; zeros(R-1,1); alpha];
     [h,t] = impz(handles.reverb.b,handles.reverb.a);
     axes(handles.axes5);
     stem(t,h); grid on;
     
     x = handles;                  % update handles
end
% --------------------------------------------------------------------------------- %

% ----------------------------------------------record, play and stop--------------------------------------------------------------- %
% --record button controls-- %
function pushbutton2_Callback(hObject, eventdata, handles)
     t = str2double(get(handles.dur,'String'));
     count = 0;
     displayTime = timer('StartFcn',@(~,~)set(handles.durdisp,'String','0'),...
                              'TimerFcn', '@(~,~)upcount(count,handles.durdisp); count = count+1',...
                              'StopFcn',@(~,~)set(handles.durdisp,'String','Done'),...
                              'ExecutionMode','FixedDelay',...
                              'Period', 1,...
                              'startDelay',1);
     record(handles.userdata.I,t);         % start recording
     start(displayTime); pause(t); stop(displayTime); delete(displayTime); clear displayTime;
     handles.userdata.data = getaudiodata(handles.userdata.I,'double');
     stop(handles.userdata.I);
     guidata(hObject, handles);                        % update handles
end

% --counter function for elapsed time-- %
function upcount(x,dispString)
     set(dispString,'String',num2str(x));
     x = x+1;
end

% --realtime plot-- %
function plotG(I,A,T,Fs,filterbank,fn)
    samples = getaudiodata(I,'double');
    samples = sum(samples,2);
    G=2;
    [~,M] = size(filterbank);
    
    % take limited end samples at every T interval
    samples = samples(round(end-T*Fs):end);
     
     % filter the data samples using filterbank
     P=zeros(M,1);
     for(k1=1:M)
          y = filter(filterbank(:,k1),1,samples);
          P(k1) = sum(y.^2)/(T*Fs);
     end
     P = P/max(P);                                          % normalize the power for plotting
     noteB = GtunePP(fn(P==1));                % find corrosponding note from the dictionary
     
     % plots %
     axes(A(1));
%      subplot(2,1,1);
     plot(0:1/Fs:T,samples); grid on;
     axis([0 T -G G]);
     title('waveform');
     
     axes(A(2));
%      subplot(2,1,2);
     plot(fn,P,'b'); grid on;
     ylim([0 1]);
     title(['note: ',noteB]);
     %     axis([0 0.08*G 0 Fs/2]);
     drawnow;
end

% --display notes-- %
function note = GtunePP(f)
     key = int8(49 + 12*log2(f/440));
     switch(key)
          case{0,12,24,36,48,60,72,84}
               note = 'A_{b}';
          case{1,13,25,37,49,61,73,85}
               note = 'A';
          case{2,14,26,38,50,62,74,86}
               note = 'B_{b}';
          case{3,15,27,39,51,63,75,87}
               note = 'B';
          case{4,16,28,40,52,64,76,88}
               note = 'C';
          case{5,17,29,41,53,65,77}
               note = 'C#';
          case{6,18,30,42,54,66,78}
               note = 'D';
          case{7,19,31,43,55,67,79}
               note = 'E_{b}';
          case{8,20,32,44,56,68,80}
               note = 'E';
          case{9,21,33,45,57,69,81}
               note = 'F';
          case{10,22,34,46,58,70,82}
               note = 'F#';
          case{11,23,35,47,59,71,83}
               note = 'G';
          otherwise
               note = '-';
     end
end


% --duration-- %
function edit2_CreateFcn(hObject, eventdata, handles)
     if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
          set(hObject,'BackgroundColor','white');
     end
     handles.dur = hObject;
     guidata(hObject, handles);                             % Update handles structure
end

function edit2_Callback(hObject, eventdata, handles)
     guidata(hObject, handles);                             % Update handles structure
end

function edit13_CreateFcn(hObject, eventdata, handles)
     if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
         set(hObject,'BackgroundColor','white');
     end
     handles.durdisp = hObject;
     guidata(hObject, handles);
end

function edit13_Callback(hObject, eventdata, handles)
     guidata(hObject, handles);
end

% --play button controls-- %
function pushbutton7_Callback(hObject, eventdata, handles)
     data_write = filter(handles.noise.b,handles.noise.a,handles.userdata.data);
     if(handles.echo.flag==1)
          data_write = filter(handles.echo.b,handles.echo.a,data_write);
     end
     if(handles.reverb.flag==1)
          data_write = filter(handles.reverb.b,handles.reverb.a,data_write);
     end
     handles.userdata.data_write = data_write/max(data_write(:));
     handles.userdata.P = audioplayer(data_write,handles.userdata.Fs);
     play(handles.userdata.P);
     guidata(hObject, handles);                             % Update handles structure
end

% --stop button controls-- %
function pushbutton3_Callback(hObject, eventdata, handles)
     stop(handles.userdata.P);
     guidata(hObject, handles);                        % update handles
end

% --save button controls-- %
function pushbutton8_Callback(hObject, eventdata, handles)
     Fname = num2str(uint64(clock));
     Fname = Fname(~isspace(Fname));
     audiowrite([Fname, '.wav'],handles.userdata.data_write,handles.userdata.Fs);
     guidata(hObject, handles);                        % update handles
end
% ---------------------------------------------------------------------------------------------------------------------- %


% -------------------------------------------noise filtering----------------------------------------------------------- %
% --low-pass cut off frequency-- %
function edit3_CreateFcn(hObject, eventdata, handles)
     if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
          set(hObject,'BackgroundColor','white');
     end
     handles.noise.Fstop = hObject;
     guidata(hObject, handles);                             % Update handles structure
end

function edit3_Callback(hObject, eventdata, handles)
     guidata(hObject, handles);                             % Update handles structure
end

% --filter gain-- %
function edit12_CreateFcn(hObject, eventdata, handles)
     if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
          set(hObject,'BackgroundColor','white');
     end
     handles.noise.gain = hObject;
     guidata(hObject, handles);                             % Update handles structure
end

function edit12_Callback(hObject, eventdata, handles)
     guidata(hObject, handles);                             % Update handles structure
end

% --generate filter-- %
function pushbutton4_Callback(hObject, eventdata, handles)
     Fstop = str2double(get(handles.noise.Fstop,'String'));
     Gain = str2double(get(handles.noise.gain,'String'));
     [handles.noise.b, handles.noise.a] = cheby2(12,80,2*Fstop/handles.userdata.Fs);
     handles.noise.b = handles.noise.b*Gain;
     [H,W] = freqz(handles.noise.b,handles.noise.a,512,handles.userdata.Fs);
     axes(handles.axes3);
     plot(W,20*log10(abs(H))); grid on;
     guidata(hObject, handles);
end
% ------------------------------------------------------------------------------------------------------------------------ %


% ----------------------------------------------------echo-------------------------------------------------------------- %
% --#echos-- %
function edit4_CreateFcn(hObject, eventdata, handles)
     if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
          set(hObject,'BackgroundColor','white');
     end
     handles.echo.N=hObject;
     guidata(hObject, handles);                             % Update handles structure
end

function edit4_Callback(hObject, eventdata, handles)
     guidata(hObject, handles);                             % Update handles structure
end

% --gap between echos-- %
function edit5_CreateFcn(hObject, eventdata, handles)
     if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
          set(hObject,'BackgroundColor','white');
     end
     handles.echo.R=hObject;
     guidata(hObject, handles);                             % Update handles structure
end

function edit5_Callback(hObject, eventdata, handles)
     guidata(hObject, handles);                             % Update handles structure
end

% --alpha-- %
function edit6_CreateFcn(hObject, eventdata, handles)
     if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
          set(hObject,'BackgroundColor','white');
     end
     handles.echo.alpha=hObject;
     guidata(hObject, handles);                             % Update handles structure
end

function edit6_Callback(hObject, eventdata, handles)
     guidata(hObject, handles);                             % Update handles structure
end

% --beta-- %
function edit7_CreateFcn(hObject, eventdata, handles)
     if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
          set(hObject,'BackgroundColor','white');
     end
     handles.echo.beta=hObject;
     guidata(hObject, handles);                             % Update handles structure
end

function edit7_Callback(hObject, eventdata, handles)
     guidata(hObject, handles);                             % Update handles structure
end

% --generate filter-- %
function pushbutton5_Callback(hObject, eventdata, handles)
     N = str2double(get(handles.echo.N,'String'));
     R = str2double(get(handles.echo.R,'String'));
     alpha = str2double(get(handles.echo.alpha,'String'));
     beta = str2double(get(handles.echo.beta,'String'));
     handles.echo.b = [1; zeros(N*R-1,1); -alpha^N];
     handles.echo.a = [1; zeros(R-1,1); -beta];
     [h,t] = impz(handles.echo.b,handles.echo.a);
     axes(handles.axes4);
     stem(t,h); grid on;
     guidata(hObject, handles);                             % Update handles structure
end

% --apply filter-- %
function checkbox1_Callback(hObject, eventdata, handles)
     t_value = get(hObject,'Value');
     if(t_value==1)
          handles.echo.flag=1;
     else
          handles.echo.flag=0;
     end
     guidata(hObject, handles);                             % Update handles structure
end
% ----------------------------------------------------------------------------------------------------------------------- %

% -------------------------------------------------reverb--------------------------------------------------------------- %
% --gap between copies-- %
function edit9_Callback(hObject, eventdata, handles)
     guidata(hObject, handles);
end

function edit9_CreateFcn(hObject, eventdata, handles)
     if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
          set(hObject,'BackgroundColor','white');
     end
     handles.reverb.R=hObject;
     guidata(hObject, handles);
end

% --alpha-- %
function edit10_Callback(hObject, eventdata, handles)
     guidata(hObject, handles);
end

function edit10_CreateFcn(hObject, eventdata, handles)
     if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
          set(hObject,'BackgroundColor','white');
     end
     handles.reverb.alpha=hObject;
     guidata(hObject, handles);
end

% --generate filter-- %
function pushbutton6_Callback(hObject, eventdata, handles)
     R = str2double(get(handles.reverb.R,'String'));
     alpha = str2double(get(handles.reverb.alpha,'String'));
     handles.reverb.b = [alpha; zeros(R-1,1); 1];
     handles.reverb.a = [1; zeros(R-1,1); alpha];
     [h,t] = impz(handles.reverb.b,handles.reverb.a);
     axes(handles.axes5);
     stem(t,h); grid on;
     guidata(hObject, handles);                             % Update handles structure
end

% --apply filter-- %
function checkbox2_Callback(hObject, eventdata, handles)
     t_value = get(hObject,'Value');
     if(t_value==1)
          handles.reverb.flag=1;
     else
          handles.reverb.flag=0;
     end
     guidata(hObject, handles);                             % Update handles structure
end
% ----------------------------------------------------------------------------------------------------------------------- %






% --------------------------------external functions-------------------------------------- %
% this function plots the frequencies and the time domain waveform for the set duration in the main code.
% The frequencies are differentiated based on the filterbank and the tone is
% shown based on a dictionary given in GtunePP.

