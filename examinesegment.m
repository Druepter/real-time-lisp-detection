function ishit = examinesegment(fftmagnitude, segment, rest)
    low = rest(1);
    high = rest(2);
    % normalized bandpass
    slicedfft = normalize.(fftmagnitude(low:high));
    % scale the segment
    scaledsegment = zeros(length(segment));
    for i = 1:length(segment)
        scaledsegment(i) = i - low;
    end
    % we have to make sure the rest segment isn't greater than the whole length
    slicemean = mean(slicedfft(scaledsegment(1):min(scaledsegment(2), end)));
    if segment(2) == length(slicedfft)
        slicemeanrest = mean(slicedfft(1:scaledsegment(1)));
    elseif segment(1) == 1
        slicemeanrest = mean(slicedfft(scaledsegment(2):end));
    else
        slicemeanrest = mean(vcat(slicedfft(1:scaledsegment(1)), slicedfft(scaledsegment(2):end)));
    end
    slicemeandiff = slicemean - slicemeanrest;
    ishit = slicemeandiff > 0;
end
