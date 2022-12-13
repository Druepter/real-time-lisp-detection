function isHit = fuellpartikel(audio, pt, f)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Globale var / initialisierung
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    fs = 48000;
    
    periodDur = 0.015;         %0.08 bei Sprachaufnahme einer weiblichen Stimme 0.015 bei einer männlichen Stimme einstellem
    
    minRegionDuration = 0.00;  %min Dauer die eine Region haben muss um berücksichtigt zu werden
    
    maxGewichtungBed1 = 2;     %regionale F0 unter globale F0
    maxGewichtungBed2 = 0.4;   %Pause vor Region länger als durchschnitts Pause
    maxGewichtungBed3 = 0;     %regionale F1 unter globale F1
    maxGewichtungBed4 = 2;     %regionale F2 unter globale F2
    
    audioPlayBack = true;      %soll Audio beim Programmstart durchgeführt werden
    deltaT = 0;                %vergrößert die wiedergegebene Dauer einer als Füllpartikel erkannten Region, um die Hörverständlichkeit beim Abspielen zu verbessern
    
    % how many filler words in the recording for it to be considered a hit
    fillerThreshold = 2;

    %%%%%%%%%%%%%Auswahl der Datei%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % audioFileName = "Bruno_Nordwind_eigeneWorte.wav";
    % audio = audioread(audioFileName);
    
    % pt = ptRead('Bruno_Nordwind_eigeneWorte.pitchTier');
    % f = formantRead('Bruno_Nordwind_eigeneWorte.Formant');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Globale f0 von pitchTierFile
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    F0Global = mean(pt.f);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   Struct beschreiben mit aufbereiteten Daten aus der PitchTier file   %
    %                                                                       %
    %   numberOfRegions     -> Anzahl erkannter Sprachregionen              %
    %   regionStart         -> Startpunkt der Region in Samples             %
    %   regionStartInSeconds-> Startpunkt der Region in Sekunden            %
    %   regionEnd           -> Endpunkt der Region in Samples               %
    %   regionEndInSeconds  -> Endpunkt der Region in Sekunden              %
    %   regionDurInSeconds  -> Dauer der Regionen                           %
    %   breakDur            -> Dauer der Pause HINTER der Region            %   
    %                                                                       %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
    
    regions = struct('numberOfRegions', [], 'regionStart',[], 'regionEnd',[] , 'regionDurInSeconds' , [] ,'regionalF0',[], 'pauseDur', [], 'regionStartInSeconds', [], 'regionEndInSeconds', []);
     
    numPitchTierEntrys = numel(pt.t);
    
    for i = 1:numPitchTierEntrys - 1
        % this doesn't seem to be reused anywhere?
        pt.delta(i) = (pt.t(i + 1) - pt.t(i));
    
        %regionEnd beschreiben  
    
        if pt.t(i+1) - pt.t(i) > periodDur                  %Ende einer Sprachregion ergibt sich aus Zeitsprüngen im pt-Array (wenn Zeitabstände größer als die Periodendauer der Frequenzermittlung werden)
            regions.regionEnd(end+1) = i;
        end
    end
    
    %regionStart beschreiben
    
    regions.regionStart = [1, (regions.regionEnd +1)];       %Beginn ist nächstes Sample nach Ende einer Region
    regions.regionStart(end) = [];
    
    %numberOfRegions beschreiben
    
    regions.numberOfRegions = width(regions.regionEnd);
    
    %regionDurInSeconds beschreiben
    
    regions.regionDurInSeconds = (pt.t(regions.regionEnd) - pt.t(regions.regionStart));
    
    % regionalF0 beschreiben 
    
    for i = 1:regions.numberOfRegions
        total = 0;
        for j = regions.regionStart(1,i):regions.regionEnd(1,i)
            total = total + pt.f(j);
        end
        regions.regionalF0(i) = total./(regions.regionEnd(1,i)-regions.regionStart(1,i)+1);
    
        % RegionStartInSeconds + RegionEndInSeconds beschreiben
    
        regions.regionStartInSeconds(i) = pt.t(regions.regionStart(i));
        regions.regionEndInSeconds(i) = pt.t(regions.regionEnd(i));
    
        % pauseDur beschreiben 
    
        if i < regions.numberOfRegions %Anfang der nächsten von dem Ende der aktuellen Region abziehen
            delta = pt.t(regions.regionStart(i+1)) - pt.t(regions.regionEnd(i));
            regions.pauseDur(i) = delta; 
        end

        %Array das angibt wieviele Füllpartikel-Kriterien in den Regionen zutreffen%
        NumberOfConditionsPerRegion(i) = 0;
    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Bedingung 1 für Füllpartikel:
        % In das Array NumberOfConditionsPerRegion +1 eintragen, wenn regionaler
        %F0-Wert unterhalb des globalen F0-Wertes liegt
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
        if regions.regionalF0(i) <= F0Global && regions.regionDurInSeconds(i) >= minRegionDuration
            weight = (abs(regions.regionalF0(i) - F0Global)/F0Global)*maxGewichtungBed1;                  %dynamische Gewichtung zwischen 0 und oben festgelegtem Maximalwert
            NumberOfConditionsPerRegion(i) = NumberOfConditionsPerRegion(i) + weight;
        end
    
    meanPauseDuration = mean(regions.pauseDur); 
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Bedingung 2 für Füllpartikel:
    % In das Array NumberOfConditionsPerRegion +1 eintragen, wenn die Pause
    % zwischen zwei Regionen die durchschnittliche Pausendauer überschreitet
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    for i = 1 : regions.numberOfRegions - 1   
        if (regions.pauseDur(i) >= meanPauseDuration) && (regions.regionDurInSeconds(i) >= minRegionDuration)
            NumberOfConditionsPerRegion(i + 1) = NumberOfConditionsPerRegion(i + 1) + maxGewichtungBed2;
        end
    end
    
    %Arrays mit F1- und F2-Werten beschreiben 
    
    f.F1 = [];
    f.F2 = [];
    
    for i = 1:f.nx
        f.F1(i) = f.frame{1, i}.frequency(1, 1);
        f.F2(i) = f.frame{1, i}.frequency(1, 2);
    end
    
    %Start- und Endpunkte der Regionen auf Abtastwerte des Formantdatensatzes übertragen 
    
    f.formantRegionStart = [];
    f.formantRegionEnd = [];
    
    j = 1;
    k = 1;
    for i = 1:f.nx
        if j <= regions.numberOfRegions 
            if f.t(i) >= regions.regionStartInSeconds(j)
                f.formantRegionStart(j) = i;
                j = j + 1; 
            end
        end
        if k <= regions.numberOfRegions 
            if f.t(i) >= regions.regionEndInSeconds(k)
                f.formantRegionEnd(k) = i;
                k = k + 1; 
            end
        end
    end
    
    % Durchschnittswerte für die Formantregionen berechnen: regionalF1 sowie
    % regionalF2
    
    totalF1 = 0;
    totalF2 = 0;
    for i = 1:regions.numberOfRegions
        totalF1 = 0;
        totalF2 = 0;
        for i = f.formantRegionStart(1,i):f.formantRegionEnd(1,i)
            totalF1 = totalF1 + f.F1(i);
            totalF2 = totalF2 + f.F2(i);
        end
        f.regionalF1(i) = totalF1./(f.formantRegionEnd(1,i)-f.formantRegionStart(1,i)+1);
        f.regionalF2(i) = totalF2./(f.formantRegionEnd(1,i)-f.formantRegionStart(1,i)+1);
    
        %globale Durchschnittswerte für F1 und F2 durch Mittelung der regionalen
        %F1- und F2-Werte
    
        totalF1 = totalF1 + f.regionalF1(i);
        totalF2 = totalF2 + f.regionalF2(i);
    end
    f.globalF1 = totalF1./regions.numberOfRegions;
    f.globalF2 = totalF2./regions.numberOfRegions;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Bedingung 3 & 4 für Füllpartikel:
    % In das Array NumberOfConditionsPerRegion +1 eintragen, wenn regionale
    %F1- bzw. F2-Werte unterhalb der globalen F1- bzw. F2-Werte liegen
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Anmerkung: dem ersten Eindruck nach liegen lokale F1-Werte von
    % Füllpartikelregionen auch häufig mal über f.globalF1 als es bei F2-Werten
    % der Fall wäre
    
    weight1 = 0;
    weight2 = 0;
    for i = 1 : regions.numberOfRegions
        if f.regionalF1(i) <= f.globalF1 && regions.regionDurInSeconds(i) >= minRegionDuration
            weight1 = (abs(f.regionalF1(i) - f.globalF1)/f.globalF1)*maxGewichtungBed3;
            NumberOfConditionsPerRegion(i) = NumberOfConditionsPerRegion(i) + weight1;
        end
         if f.regionalF2(i) <= f.globalF2 && regions.regionDurInSeconds(i) >= minRegionDuration
             weight2 = (abs(f.regionalF2(i) - f.globalF2)/f.globalF2)*maxGewichtungBed4;
            NumberOfConditionsPerRegion(i) = NumberOfConditionsPerRegion(i) + weight2;
        end
    end 
    
    isHit = 0;
    if numOfFillerVocables > fillerThreshold
        isHit = 1;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%vorbereitung Display Plots
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %numOfFillerVocables = 0;
    
    %maxWeight = sum([maxGewichtungBed1, maxGewichtungBed2, maxGewichtungBed3, maxGewichtungBed4]);      %maximal theoretisch mögliche Bewertung einer Sprachregion
    %numOfFillerVocables = sum(NumberOfConditionsPerRegion(:) > 0.2*maxWeight);                          %Regionen auf die alle Bedingungen zutreffen 
    %listOfUsedWeights = unique(NumberOfConditionsPerRegion);                                            %Abstufungen aller Gewichtungs-Faktoren 
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%Command Window displays
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %fprintf('\nDas File %s wurde analysiert.\n', audioFileName);
    %fprintf('\nDabei wurden %d Füllpartikel erkannt.\n', numOfFillerVocables);
    %fprintf('Weitere Informationen:\n');
    %fprintf('Abtastrate: %dHz;\tMindestdauer einer Region: %g sek\n', fs, minRegionDuration);
    %fprintf('\nGewichtung Grundfrequenz-Bedingung:\t%d\n', maxGewichtungBed1);
    %fprintf('Gewichtung Pausen-Bedingung:\t\t%d\n', maxGewichtungBed2);
    %fprintf('Gewichtung 1ste-Formant-Bedingung:\t%d\n', maxGewichtungBed3);
    %fprintf('Gewichtung 2te-Formant-Bedingung:\t%d\n', maxGewichtungBed4);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%Graph Displays
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %if width(audio) == 2
    %    audio(:,2) = [];                                                                    %Samplearray zu mono konvertieren
    %end
    %[s, a] = size(audio);                                                                   %dimensionen des Audiofiles für das spätere Plotten
    %tiledlayout(2,1)
    %nexttile
    
    %t=linspace(0,length(audio)/fs,length(audio));
    %plot(t,audio);
    %xlabel('time');
    %ylabel('Amp');
    %title(audioFileName);
    
    %nexttile
    
    %h = histogram(NumberOfConditionsPerRegion);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%Audio abspielen 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %if audioPlayBack
    %    regionsOfFillerVocables = find(NumberOfConditionsPerRegion > 0.2*maxWeight, 50);        %Wiedergabe aller Regionen, die mit mindetstens 20% der theoretisch möglichen Maximalbewertung gewichtet wurde 
        
    %    currentStep = 1;
    %    for i=1:numOfFillerVocables
    %        startInSamples = round((regions.regionStartInSeconds(regionsOfFillerVocables(i))-deltaT) * fs);   %z. B. deltaT = 0.5 s, um besesr reinhören zu können
    %        endInSamples = round((regions.regionEndInSeconds(regionsOfFillerVocables(i))+deltaT) * fs);       
    %        numberOfSamples = endInSamples - startInSamples;
    %        continousFillerVocableSampleData(currentStep:(currentStep+numberOfSamples), 1) = audio(startInSamples:endInSamples, 1); %Aneinanderreihung aller Samples die zu einem erkannten FP gehören
    
    %        currentStep = currentStep + numberOfSamples; 
    %    end
    
    %    player = audioplayer(continousFillerVocableSampleData, fs);
    %    play(player);                                                      
    %end
end
