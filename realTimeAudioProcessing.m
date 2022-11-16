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
% these are just based on my results from the julia script
normalFreqs = [1052, 1352];
lispFreqs = [5517, 6514];
restFreqs = [1000, 22050];

%% loop over analyze
i = 1;
count = 0;

tic
while toc
     x = step(In);
     y = x;

     step(Out, y);

     % actually run the analyze
     % +1 for lisp and -1 for non-lisp
     count = count + lispanalyze(x, sampleRate, normalFreqs, lispFreqs, restFreqs);

     if i == 10
         % check if lisping beats out non-lisping
         if count > 0
             % this is where the actual warning should be
             disp("Lots of lisping!")
         end
     else
         i = i + 1;
     end
end    

