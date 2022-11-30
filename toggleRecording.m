function [] = toggleRecording(isRunning)
    % if the recording isn't running yet we have to start it
    if isRunning == 0
        % sox is a good lightweight choice for a cross-platform audio recorder
        % https://sox.sourceforge.net/
        % it is impossible to pass MATLAB variables to the bang operator
        % so unforunately we have to use a generic filename as a fallback for now
        % the alternative would be piping current time from eg timedatectl
        !sox -d recording.wav
    else
        % various ways to kill the sox recording
        % linux should work fine - I don't have a system to test the others though
        if ispc
            !taskkill /IM sox.exe
        elseif isunix || ismac
            !killall sox
        else
            disp("Unknown platform detected!")
        end
    end
end
