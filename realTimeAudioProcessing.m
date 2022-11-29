%% initialize audio devices
% input audio device
In = audioDeviceReader;
In.Device = "default";

% set frame window in samples
frameLength = 0.5; % seconds
sampleRate = In.SampleRate;
In.SamplesPerFrame = sampleRate * frameLength;

% output audio device
Out = audioDeviceWriter;
Out.Device = "default";

%% default values
mode = "lisp";
% these are just based on my results from the julia script
normalFreqs = [1052, 1352];
lispFreqs = [5517, 6514];
restFreqs = [1000, 22050];
params = [normalFreqs', lispFreqs', restFreqs'];

%% loop over analyze
i = 0;
count = 0;

tic
while toc
     x = step(In);
     y = x;

     step(Out, y);

     % actually run the analyze
     i, count = callAnalyze(mode, i, count, x, params);
end    

