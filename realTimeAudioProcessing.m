clc;
clear;

meineVariable = "huhu";

fprintf(meineVariable);

%File = dsp.AudioFileReader('Nordwind_Bruno_entspannt-deutlich.wav');
%Fs = File.SampleRate;

%Out = audioDeviceWriter('SampleRate', Fs);

In = audioDeviceReader;
In.Device = "default";

Out = audioDeviceWriter;
Out.Device = "default";

tic
while toc

     x = step(In);
     y = x;

     step(Out, y)

     plot(x)
     drawnow

end    


%{
recDuration = 5
disp("Begin speaking.")
recordblocking(recObj,recDuration)
disp("End of recording.")
%}

%play(recObj);

%y = getaudiodata(recObj);

%plot(y);


