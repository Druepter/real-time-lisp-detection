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
normalFreqs = strsplit(normalFreqs,',');
normalFreqs = str2double(normalFreqs);

% get lispFreqs from cell array
lispFreqs = calibration{1}(4, 1);
lispFreqs = cell2mat(lispFreqs);
lispFreqs = strsplit(lispFreqs,',');
lispFreqs = str2double(lispFreqs);

% get lispFreqs from cell array
restFreqs = calibration{1}(5, 1);
restFreqs = cell2mat(restFreqs);
restFreqs = strsplit(restFreqs,',');
restFreqs = str2double(restFreqs);


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
     i, count = callAnalyze(mode, i, count, params);
end    

