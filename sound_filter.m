% this script listens to the music, filters appropriately and stores it

%% misc %%
clear;
clc;

%% intialisation %%
Fs=11025;                % sampling frequency
NBIT=16;                % #bits
NCHANS=2;               % #channels
T=0.08;                 % time frame(block) in seconds
t=10;                   % time duration for recording in seconds
M=64;                  % Mpoint FFT
F0=554;                  % fundamental frequency (A4)
gr=2^(1/12);             % harmony golden ratio

% create filterbank %
key=(0:88)';
fn = F0 * gr.^(key-49);
Ts = 1/Fs;
n = (0:Ts:T)';
filterbank = cos(2*pi*n*fn');

% object creation %
I = audiorecorder(Fs,NBIT,NCHANS);

% setting object properties %
set(I,'TimerFcn',@(I,~)plotG(I,0,T,Fs,filterbank,fn),'TimerPeriod',T);

%% execution %%
% recording %
recordblocking(I,t);

% take data for procesing %
data = getaudiodata(I,'double');
stop(I);

%% noise removal %%
Fstop = 4500;                                                         % stopband freq in Hz
[b_noise, a_noise] = cheby2(4,80,2*Fstop/Fs);
data = filter(b_noise,a_noise,data);

%% reverb effect %%
gamma = 0.5;
Rreverb=2;
Gr=1;
b_reverb = [gamma; zeros(Rreverb-1,1); 1];
a_reverb = [1;zeros(Rreverb-1,1); gamma];
impz(b_reverb,a_reverb);

%% echo effect %%
Necho=3;
Recho=2;
alpha=0.5;
beta=0.5;
Ge=1;
b_echo = [1; zeros(Necho*Recho-1,1); -alpha^Necho];
a_echo = [1; zeros(Recho-1,1); -beta];
axes
axes
impz(b_echo,a_echo);

%% apply filters %%
data_write = filter(Ge*b_echo,a_echo,data);
% data_write = filter(Gr*b_reverb,a_reverb,data_write);

%% save data %%
% audiowrite('rec.wav',data,Fs);
P = audioplayer(data_write, Fs);
play(P);













