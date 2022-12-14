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
    
    % audioPlayBack = true;      %soll Audio beim Programmstart durchgeführt werden
    % deltaT = 0;                %vergrößert die wiedergegebene Dauer einer als Füllpartikel erkannten Region, um die Hörverständlichkeit beim Abspielen zu verbessern
    
    % how many filler words in the recording for it to be considered a hit
    fillerThreshold = 2;
   
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
        % pt.delta(i) = (pt.t(i + 1) - pt.t(i));
    
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
    
    NumberOfConditionsPerRegion = [];
    
    for i = 1:regions.numberOfRegions
        % regionalF0 beschreiben 
    
        total = 0;
        for j = regions.regionStart(1,i):regions.regionEnd(1,i)
            total = total + pt.f(j);
        end
        regionalF0 = total./(regions.regionEnd(1,i)-regions.regionStart(1,i)+1);
    
        % RegionStartInSeconds + RegionEndInSeconds beschreiben
    
        regions.regionStartInSeconds(i) = pt.t(regions.regionStart(i));
        regions.regionEndInSeconds(i) = pt.t(regions.regionEnd(i));
    
        % pauseDur beschreiben 
    
        if i < regions.numberOfRegions %Anfang der nächsten von dem Ende der aktuellen Region abziehen
            regions.pauseDur(i) = pt.t(regions.regionStart(i+1)) - pt.t(regions.regionEnd(i));
        end
    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Bedingung 1 für Füllpartikel:
        % In das Array NumberOfConditionsPerRegion +1 eintragen, wenn regionaler
        %F0-Wert unterhalb des globalen F0-Wertes liegt
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % NumberOfConditionsPerRegion = Array das angibt wieviele Füllpartikel-Kriterien in den Regionen zutreffen%
    
        NumberOfConditionsPerRegion(i) = 0;
        if regionalF0 <= F0Global && regions.regionDurInSeconds(i) >= minRegionDuration
            weight = (abs(regionalF0 - F0Global)/F0Global)*maxGewichtungBed1;                  %dynamische Gewichtung zwischen 0 und oben festgelegtem Maximalwert
            NumberOfConditionsPerRegion(i) = NumberOfConditionsPerRegion(i) + weight;
        end
    end
    
    meanPauseDuration = mean(regions.pauseDur); 
       
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
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Bedingung 2 für Füllpartikel:
        % In das Array NumberOfConditionsPerRegion +1 eintragen, wenn die Pause
        % zwischen zwei Regionen die durchschnittliche Pausendauer überschreitet
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        if i < regions.numberOfRegions
            if (regions.pauseDur(i) >= meanPauseDuration) && (regions.regionDurInSeconds(i) >= minRegionDuration)
                NumberOfConditionsPerRegion(i + 1) = NumberOfConditionsPerRegion(i + 1) + maxGewichtungBed2;
            end
        end

        totalF1 = 0;
        totalF2 = 0;
        for j = f.formantRegionStart(1,i):f.formantRegionEnd(1,i)
            totalF1 = totalF1 + f.F1(j);
            totalF2 = totalF2 + f.F2(j);
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
    
    for i = 1 : regions.numberOfRegions
        if regions.regionDurInSeconds(i) >= minRegionDuration
            if f.regionalF1(i) <= f.globalF1
                weight = (abs(f.regionalF1(i) - f.globalF1)/f.globalF1)*maxGewichtungBed3;
                NumberOfConditionsPerRegion(i) = NumberOfConditionsPerRegion(i) + weight;
            end
            if f.regionalF2(i) <= f.globalF2
                weight = (abs(f.regionalF2(i) - f.globalF2)/f.globalF2)*maxGewichtungBed4;
                NumberOfConditionsPerRegion(i) = NumberOfConditionsPerRegion(i) + weight;
            end
        end
    end 
    
    isHit = 0;
    hitCondition = 0.2 * sum([maxGewichtungBed1, maxGewichtungBed2, maxGewichtungBed3, maxGewichtungBed4]);
    numHits = sum(NumberOfConditionsPerRegion(:) > hitCondition);
    if numHits > fillerThreshold
        isHit = 1;
    end
end
