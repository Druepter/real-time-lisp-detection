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
%mode = "lisp";
% these are just based on my results from the julia script
%normalFreqs = [1052, 1352];
%lispFreqs = [5517, 6514];
%restFreqs = [1000, 22050];
%params = [normalFreqs', lispFreqs', restFreqs'];


%% read calibration file
fileName = fopen('calibration.config');
formatSpec = '%q';
% save file to cell array
calibration = textscan(fileName,formatSpec);

% get mode from cell array 
mode = calibration{1}(1, 1);
mode = string(mode);

% get normalFreqs from cell array
normalFreqs = calibration{1}(3, 1);
normalFreqs = cell2mat(normalFreqs);

% get lispFreqs from cell array
lispFreqs = calibration{1}(4, 1);
lispFreqs = cell2mat(lispFreqs);

% get lispFreqs from cell array
restFreqs = calibration{1}(4, 1);
restFreqs = cell2mat(restFreqs);

%% loop over analyze
i = 0;
count = 0;

tic
while toc
     x = step(In);
     y = x;

     step(Out, y);

     % actually run the analyze
     i, count = callAnalyze(mode, i, count, params);
end    

