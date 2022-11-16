function islisp = lispanalyze(audio, fs, normal, lisp, rest)
    disp("analyzing...")

    % use standard deviation to detect speech
    % the julia script used a larger audio file as reference
    % and compared segment means to the full audio file's to
    % determine silence but this is easier on memory
    % an alternative to this would be a noise gate or a
    % reference mean found during calibration
    disp(std(audio))

    audiofft = fft(audio);

    % return 1 if this segment is a lisp and -1 if non-lisp
    if examinesegment(audiofft, lisp, rest)
        disp("Lisp detected!")
        islisp = 1;
    elseif examinesegment(audiofft, normal, rest)
        disp("No lisp detected!")
        islisp = -1;
    end
    % otherwise return 0
    islisp = 0;
end
