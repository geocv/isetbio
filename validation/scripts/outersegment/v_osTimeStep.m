function varargout = v_osTimeStep(varargin)
%
% Demonstrate simulations using three different timebases, one for stimuli (based on stimulus refresh rate), 
% one for absorptions and eye movements (based on coneMosaic.integrationTime), and a third one for 
% outer segment current computations (based on os.timeStep) 
% Also demonstrates usage of the computeForOISequence() method of @coneMosaic, which computes 
% absorptions and photocurrents for a sequence of sequentially presented optical images with eye movements.
%
% NPC, ISETBIO TEAM, 2016
%

    varargout = UnitTest.runValidationRun(@ValidationFunction, nargout, varargin);
end

%% Function implementing the isetbio validation code
function ValidationFunction(runTimeParams)

%% Init
ieInit;

% scene mean luminance
meanLuminance = 400;  
    
% Steady params
c0 = struct(...
    'mosaicSize', nan, ...                      % 1 L-, 1 M-, and 1 S-cone only
    'meanLuminance', meanLuminance, ...         % scene mean luminance
    'modulation', 1.0, ...                      % 100%  modulation against background
    'modulationRegion', 'FULL', ...             % modulate the central image (choose b/n 'FULL', and 'CENTER')
    'stimulusSamplingInterval',  0.12, ...      % 8.3- Hz stimulus refresh, e.g., 100 msec per optical image
    'osTimeStep', 1/1000, ...                   % 1 millisecond
    'integrationTime', nan, ...                 % we will vary this one
    'photonNoise', true, ...
    'osNoise', false);

% Generate 1000 response instances
instancesNum = 500;

    
    
% 60 ms integrationTime
stimulusConditionIndex = 1;
theCondition = c0;
theCondition.integrationTime = 60/1000;                  
c{stimulusConditionIndex} = theCondition;

[theConeMosaic, theOIsequence, ...
 isomerizationRateSequence, photoCurrentSequence, ...
 oiTimeAxis, absorptionsTimeAxis, photoCurrentTimeAxis, ...
 allInstancesAbsorptionsCountSequence60msec, ...
 allInstancesIsomerizationRateSequence60msec, ...
 allInstancesPhotoCurrentSequence60msec] = runSimulation(c{stimulusConditionIndex}, instancesNum);  

plotSNR(absorptionsTimeAxis, oiTimeAxis, ...
        allInstancesAbsorptionsCountSequence60msec, ...
        mean(allInstancesAbsorptionsCountSequence60msec, 4), ...
        std(allInstancesAbsorptionsCountSequence60msec, 0, 4), ...
        photoCurrentTimeAxis, ...
        mean(allInstancesPhotoCurrentSequence60msec,4), ...
        std(allInstancesPhotoCurrentSequence60msec, 0, 4), ...
        stimulusConditionIndex*10);


% 30 ms integrationTime
stimulusConditionIndex = 2;
theCondition = c0;
theCondition.integrationTime = 30/1000;                  
c{stimulusConditionIndex} = theCondition;

[theConeMosaic, theOIsequence, ...
 isomerizationRateSequence, photoCurrentSequence, ...
 oiTimeAxis, absorptionsTimeAxis, photoCurrentTimeAxis, ...
 allInstancesAbsorptionsCountSequence30msec, ...
 allInstancesIsomerizationRateSequence30msec, ...
 allInstancesPhotoCurrentSequence30msec] = runSimulation(c{stimulusConditionIndex}, instancesNum);  



plotSNR(absorptionsTimeAxis, oiTimeAxis, ...
        allInstancesAbsorptionsCountSequence30msec, ...
        mean(allInstancesAbsorptionsCountSequence30msec, 4), ...
        std(allInstancesAbsorptionsCountSequence30msec, 0, 4), ...
        photoCurrentTimeAxis, ...
        mean(allInstancesPhotoCurrentSequence30msec,4), ...
        std(allInstancesPhotoCurrentSequence30msec, 0, 4), ...
        stimulusConditionIndex*10);
    
    
% Plot the results from last instance
%plotEverything(theConeMosaic, theOIsequence, isomerizationRateSequence, photoCurrentSequence, oiTimeAxis, absorptionsTimeAxis, photoCurrentTimeAxis, stimulusConditionIndex, c{stimulusConditionIndex});


end


function plotSNR(time, oiTimeAxis, allInstancesIsomerizationsCount, isomerizationMeans, isomerizationSTDs, photocurrentTime, photocurrentMeans, photocurrentSTDs, figNo)
    hFig = figure(figNo); clf;
    set(hFig, 'Position', [10+figNo*10 10 1800 1180], 'Color', [0 0 0]);
    
    colors = [1 0 0; 0 1.0 0; 0 0.8 1];
    coneNames = {'L-cone', 'M-cone', 'S-cone'};
    
    dt = time(2)-time(1);
    instancesNum = size(allInstancesIsomerizationsCount,4);
    SNRlim = [0 90; 0 90; 0 30];
    photocurrentRange = [-50 -10];
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
           'rowsNum', 3, ...
           'colsNum', 4, ...
           'heightMargin',   0.04, ...
           'widthMargin',    0.05, ...
           'leftMargin',     0.05, ...
           'rightMargin',    0.00, ...
           'bottomMargin',   0.04, ...
           'topMargin',      0.04);
    
    for coneType = 1:3
        mu = squeeze(isomerizationMeans(1,coneType,:));
        sigma = squeeze(isomerizationSTDs(1,coneType,:));
        variance = sigma.^2;
        FanoFactor = mu ./ variance;
        SNR = mu ./ sigma;
        
        maxIsomerizationCountForThisCone = max(max(max(squeeze(allInstancesIsomerizationsCount(:,coneType, :,:)))));
        minIsomerizationCountForThisCone = min(min(min(squeeze(allInstancesIsomerizationsCount(:,coneType, :,:)))));
        
        % Absorption events
        subplot('Position', subplotPosVectors(coneType,1).v);
        hold on
        % Identify stimulus presentation times
        for k = 1:numel(oiTimeAxis)
            plot(oiTimeAxis(k)*[1 1], [minIsomerizationCountForThisCone maxIsomerizationCountForThisCone], 'k-', 'Color', [0.5 0.5 0.5]);
        end
        
        barOpacity = 0.1;
        for tIndex = 1:numel(time)
            quantaAtThisTimeBin = squeeze(allInstancesIsomerizationsCount(:,coneType,tIndex,:));
            plot([time(tIndex) time(tIndex)+dt], [quantaAtThisTimeBin(:) quantaAtThisTimeBin(:)], '-', 'LineWidth', 1.5, 'Color', [colors(coneType,:) barOpacity]);
        end
        box on;
        set(gca, 'XColor', [0.8 0.8 0.8], 'YColor', [0.8 0.8 0.8], 'Color', [0.2 0.2 0.2], 'FontSize', 14, 'XLim', [time(1) time(end)+dt], 'YLim', [minIsomerizationCountForThisCone maxIsomerizationCountForThisCone]);
        if (coneType == 3)
            xlabel('time (seconds)', 'FontSize', 16);
        end
        ylabel(sprintf('quanta in %2.1f msec', 1000*dt), 'FontSize', 16, 'FontWeight', 'bold', 'Color', [1 1 0.3]);
        title(sprintf('%s isomerizations (%d instances)', coneNames{coneType}, instancesNum), 'FontSize', 16, 'Color', [1 1 1]);

        % Absorptions FanoFactor
        subplot('Position', subplotPosVectors(coneType,2).v);
        hold on
        % Identify stimulus presentation times
        for k = 1:numel(oiTimeAxis)
            plot(oiTimeAxis(k)*[1 1], [0.5 2], 'k-', 'Color', [0.5 0.5 0.5]);
        end
        % Identify the FanoFactor = 1 line
        plot([time time(end)+dt], [ones(size(time)) 1], '--', 'Color', [0.8 0.8 0.3], 'LineWidth', 1.5);
        for tIndex = 1:numel(time)
            if (tIndex < numel(time))
                xx = [time(tIndex) time(tIndex)+dt time(tIndex+1)];
                yy = [FanoFactor(tIndex) * [1 1] FanoFactor(tIndex+1)];
            else
                xx = [time(tIndex) time(tIndex)+dt];
                yy = FanoFactor(tIndex) * [1 1];
            end
            plot(xx,yy, '-', 'Color', colors(coneType,:), 'LineWidth', 1.5);
        end
        box on;
        yTicks = [0.5 0.75 1.0 1/0.75 1/0.5];
        set(gca, 'XColor', [0.8 0.8 0.8], 'YColor', [0.8 0.8 0.8], 'Color', [0.2 0.2 0.2], 'FontSize', 14, 'XLim', [time(1) time(end)+dt], 'YLim', [0.5 2.0], 'YScale', 'Log', 'YTick', yTicks, 'YTickLabel', sprintf('%2.2f\n', yTicks));
        if (coneType == 3)
            xlabel('time (seconds)', 'FontSize', 16);
        end
        ylabel('quanta Fano factor ( \mu/{\sigma}^2 )', 'FontSize', 16, 'FontWeight', 'bold', 'Color', [1 1 0.3]);
        title('Fano Factor', 'FontSize', 16, 'Color', [1 1 1]);
        
        
        % Absorptions SNR
        subplot('Position', subplotPosVectors(coneType,3).v);
        hold on
        % Identify stimulus presentation times
        for k = 1:numel(oiTimeAxis)
            plot(oiTimeAxis(k)*[1 1], SNRlim(coneType,:), 'k-', 'Color', [0.5 0.5 0.5]);
        end

        for tIndex = 1:numel(time)
            if (tIndex < numel(time))
                xx = [time(tIndex) time(tIndex)+dt time(tIndex+1)];
                yy = [SNR(tIndex) * [1 1] SNR(tIndex+1)];
            else
                xx = [time(tIndex) time(tIndex)+dt];
                yy = SNR(tIndex) * [1 1];
            end
            plot(xx,yy, '-', 'Color', colors(coneType,:), 'LineWidth', 1.5);
        end
        box on;
        %yTicks = [0.5 0.75 1.0 1/0.75 1/0.5];
        set(gca, 'XColor', [0.8 0.8 0.8], 'YColor', [0.8 0.8 0.8], 'Color', [0.2 0.2 0.2], 'FontSize', 14, 'XLim', [time(1) time(end)+dt],  'YLim', SNRlim(coneType,:), 'YScale', 'Linear');
        if (coneType == 3)
            xlabel('time (seconds)', 'FontSize', 16);
        end
        ylabel('quanta SNR ( \mu/\sigma )', 'FontSize', 16, 'FontWeight', 'bold', 'Color', [1 1 0.3]);
        title('SNR', 'FontSize', 16, 'Color', [1 1 1]);
        
        
        % photocurrents
        meanCurrent = squeeze(photocurrentMeans(1,coneType,:));
        sigmaCurrent = squeeze(photocurrentSTDs(1,coneType,:));
        
        subplot('Position', subplotPosVectors(coneType,4).v);
        % Identify stimulus presentation times
        hold on
        for k = 1:numel(oiTimeAxis)
            plot(oiTimeAxis(k)*[1 1], photocurrentRange, 'k-', 'Color', [0.5 0.5 0.5]);
        end
        
        % Plot photocurrents
        x = [photocurrentTime(1) photocurrentTime photocurrentTime(end:-1:1) photocurrentTime(1)];
        y = [sigmaCurrent(1); sigmaCurrent; -sigmaCurrent(end:-1:1); sigmaCurrent(1)] + ...
            [meanCurrent(1);  meanCurrent;   meanCurrent(end:-1:1);  meanCurrent(1)];
        patch(x,y, 0.25*colors(coneType,:)+0.75*[1 1 1]); hold on
        plot(photocurrentTime, meanCurrent, '-', 'Color', 0.5*colors(coneType,:), 'LineWidth', 1.5);
        box on;
        set(gca, 'XColor', [0.8 0.8 0.8], 'YColor', [0.8 0.8 0.8], 'Color', [0.2 0.2 0.2], 'FontSize', 14, 'XLim', [time(1) time(end)+dt], 'YLim', photocurrentRange);
        if (coneType == 3)
            xlabel('time (seconds)', 'FontSize', 16);
        end
        ylabel('photocurrent (pA)', 'FontSize', 16, 'FontWeight', 'bold', 'Color', [1 1 0.3]);
        title('Pphotocurrent (+/- sigma), os.noiseFlag = false', 'FontSize', 16, 'Color', [1 1 1]);
        
        drawnow;
    end
    
    %NicePlot.exportFigToPNG(sprintf('Fig%d.png', figNo), hFig, 300);
end

function [theConeMosaic, theOIsequence, ...
    isomerizationRateSequence, photoCurrentSequence, ...
    oiTimeAxis, absorptionsTimeAxis, photoCurrentTimeAxis, ...
    allInstancesAbsorptionsCountSequence, ...
    allInstancesIsomerizationRateSequence, ...
    allInstancesPhotoCurrentSequence] = runSimulation(condData, instancesNum)

    mosaicSize = condData.mosaicSize;
    meanLuminance = condData.meanLuminance;
    modulation = condData.modulation;
    modulationRegion = condData.modulationRegion;
    stimulusSamplingInterval = condData.stimulusSamplingInterval;
    integrationTime = condData.integrationTime;
    osTimeStep = condData.osTimeStep;
    photonNoise = condData.photonNoise; 
    osNoise = condData.osNoise;
    
    % Define the time axis for the simulation (how much data we will generate)
    oiTimeAxis = -0.6:stimulusSamplingInterval:0.4;
    stimulusRampTau = 0.165;

    % Generate a uniform field scene with desired mean luminance
    if (isnan(mosaicSize))
        FOV = 0.2;
    else
        FOV = max(mosaicSize);
    end
    theScene = uniformFieldSceneCreate(FOV, meanLuminance);

    % Generate optics
    noOptics = false;
    theOI = oiGenerate(noOptics);

    % Generate the sequence of optical images
    theOIsequence = oiSequenceGenerateForRampedSceneModulation(theScene, theOI, oiTimeAxis, stimulusRampTau, modulation, modulationRegion);

    % Generate the cone mosaic with eye movements for theOIsequence
    theConeMosaic = coneMosaicGenerate(mosaicSize, photonNoise, osNoise, integrationTime, osTimeStep, oiTimeAxis, numel(theOIsequence));

    % Make all movements 0.
    theConeMosaic.emPositions = theConeMosaic.emPositions * 0;
    
    % Compute instancesNum times (note: eyeMovements remain unchanged from instance to instance)
    for instanceIndex = 1:instancesNum
        fprintf('Computing instance %d / %d\n', instanceIndex, instancesNum);
        [absorptionsCountSequence, absorptionsTimeAxis, photoCurrentSequence, photoCurrentTimeAxis] = ...
            theConeMosaic.computeForOISequence(theOIsequence, oiTimeAxis, ...
            'currentFlag', true, ...
            'newNoise', true ...
            );
        % Compute photon rate from photon count
        isomerizationRateSequence = absorptionsCountSequence / theConeMosaic.integrationTime;
    
        % Preallocate memory
        if (instanceIndex == 1)
            allInstancesAbsorptionsCountSequence = zeros([size(absorptionsCountSequence) instancesNum ]);
            allInstancesIsomerizationRateSequence = zeros([size(isomerizationRateSequence) instancesNum ]);
            allInstancesPhotoCurrentSequence = zeros([size(photoCurrentSequence) instancesNum ]);
        end
        
        allInstancesAbsorptionsCountSequence(:,:,:, instanceIndex) = absorptionsCountSequence;
        allInstancesIsomerizationRateSequence(:,:,:, instanceIndex) = isomerizationRateSequence;
        allInstancesPhotoCurrentSequence(:,:,:, instanceIndex) = photoCurrentSequence;
    end
end


% ------- Helper functions --------

function theConeMosaic = coneMosaicGenerate(mosaicSize, photonNoise, osNoise, integrationTime, osTimeStep, oiTimeAxis, opticalImageSequenceLength)
    % Default human mosaic
    theConeMosaic = coneMosaic;
    
    % Adjust size
    if isnan(mosaicSize)
        % Generate a human cone mosaic with 1L, 1M and 1S cone
        theConeMosaic.rows = 1;
        theConeMosaic.cols = 3;
        theConeMosaic.pattern = [2 3 4];
    else
        theConeMosaic.setSizeToFOV(mosaicSize);
    end
    
    % Set the noise
    theConeMosaic.noiseFlag = photonNoise;

    % Set the integrationTime
    theConeMosaic.integrationTime = integrationTime;
    
    % Generate the outer-segment object to be used by the coneMosaic
    theOuterSegment = osLinear();
    theOuterSegment.noiseFlag = osNoise;
    
    % Set a custom timeStep, for @osLinear we do not need the default 0.1 msec
    theOuterSegment.timeStep = osTimeStep;

    % Couple the outersegment object to the cone mosaic object
    theConeMosaic.os = theOuterSegment;

    % Generate eye movement sequence for all oi's
    stimulusSamplingInterval = oiTimeAxis(2)-oiTimeAxis(1);
    eyeMovementsNumPerOpticalImage = stimulusSamplingInterval/theConeMosaic.integrationTime;
    eyeMovementsNum = round(eyeMovementsNumPerOpticalImage*opticalImageSequenceLength);
    
    if (eyeMovementsNum < 1)
        error('Less than 1 eye movement!!! \nStimulus sampling interval:%g Cone mosaic integration time: %g\n', stimulusSamplingInterval, theConeMosaic.integrationTime);
    else 
        fprintf('Optical image sequence contains %2.0f eye movements (%2.2f eye movements/oi)\n', eyeMovementsNum, eyeMovementsNumPerOpticalImage);
        theConeMosaic.emGenSequence(eyeMovementsNum);
    end
end


function theOIsequence = oiSequenceGenerateForRampedSceneModulation(theScene, theOI, oiTimeAxis, stimulusRampTau, modulation, modulationRegion)
    % Stimulus time ramp
    stimulusRamp = exp(-0.5*(oiTimeAxis/stimulusRampTau).^2);
    
    % Compute the optical image
    theOI = oiCompute(theOI, theScene);
    backgroundPhotons = oiGet(theOI, 'photons');
    
    fprintf('Computing sequence of optical images\n');
    
    for stimFrameIndex = 1:numel(oiTimeAxis)
        if strcmp(modulationRegion, 'FULL')
            retinalPhotonsAtCurrentFrame = backgroundPhotons * (1.0 + modulation*stimulusRamp(stimFrameIndex));
        elseif strcmp(modulationRegion, 'CENTER')
            if (stimFrameIndex == 1)
                pos = oiGet(theOI, 'spatial support', 'microns');
                ecc = sqrt(squeeze(sum(pos.^2, 3)));
                idx = find(ecc < 0.5*max(pos(:)));
                [idx1, idx2] = ind2sub(size(ecc), idx);
            end
            retinalPhotonsAtCurrentFrame = backgroundPhotons;
            retinalPhotonsAtCurrentFrame(idx1, idx2, :) = retinalPhotonsAtCurrentFrame(idx1, idx2, :) * (1.0 + modulation*stimulusRamp(stimFrameIndex));
        else
            error('Unknown modulationRegion ''%s'', modulationRegion');
        end
        theOIsequence{stimFrameIndex} = oiSet(theOI, 'photons', retinalPhotonsAtCurrentFrame);
    end
end


function theOI = oiGenerate(noOptics)
    % Generate optics
    if (noOptics)
        theOI = oiCreate('diffraction limited');
        optics = oiGet(theOI,'optics');           
        optics = opticsSet(optics,'fnumber',0);
        optics = opticsSet(optics, 'off axis method', 'skip');
        theOI = oiSet(theOI,'optics', optics);
    else
        theOI = oiCreate('human');
    end
end


function uniformScene = uniformFieldSceneCreate(FOV, meanLuminance)
    uniformScene = sceneCreate('uniformd65');
    % square scene with desired FOV
    uniformScene = sceneSet(uniformScene, 'wAngular', FOV);
    % 1 meter away
    uniformScene = sceneSet(uniformScene, 'distance', 1.0);
    % set some radiance (in photons/steradian/m^2/nm)
    photonFlux = 1e16;
    uniformScene = sceneSet(uniformScene, 'photons', photonFlux*ones(64,64,numel(sceneGet(uniformScene, 'wave'))));
    % adjust radiance according to desired  mean luminance
    uniformScene = sceneAdjustLuminance(uniformScene, meanLuminance);
end


function plotEverything(theConeMosaic, theOIsequence, isomerizationRateSequence, photoCurrentSequence, oiTimeAxis, absorptionsTimeAxis, responseTimeAxis, figNo, condData)

    % Plot the sequence of OIs with the eye movements 
    hFig = figure(figNo); clf;
    set(hFig, 'Position', [10+figNo*50 10+figNo*100 1920 760], 'Color', [1 1 1]);
    set(hFig, 'Name', sprintf('Scene Mean Luminance: %2.1f cd/m2,     Modulation: %2.2f,     Stimulus Sampling: %2.1f ms,     Integration Time: %2.1f ms,   Response Sampling: %2.1f ms,      PhotonNoise: %g,      osNoise: %g', condData.meanLuminance, condData.modulation, condData.stimulusSamplingInterval*1000, condData.integrationTime*1000, condData.osTimeStep*1000, condData.photonNoise, condData.osNoise));

    tabGroup = uitabgroup('Parent', hFig);
    
    eyeMovementsTab = uitab(tabGroup, 'Title', '2D eye movements and OI sequence', 'BackgroundColor', [1 1 1], 'ForegroundColor', [0 0 1]);
    timeSeriesTab = uitab(tabGroup, 'Title', 'Time series: optical image photon rate, eye movements, aborptions, & photocurrents', 'BackgroundColor', [1 1 1], 'ForegroundColor', [0 0 1]);
    
    set(tabGroup, 'SelectedTab',eyeMovementsTab);
    axes('parent',eyeMovementsTab);

    
    plotRows = round(0.75*sqrt(numel(theOIsequence))); 
    plotCols = ceil(numel(theOIsequence)/plotRows);
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
           'rowsNum', plotRows, ...
           'colsNum', plotCols, ...
           'heightMargin',   0.03, ...
           'widthMargin',    0.03, ...
           'leftMargin',     0.03, ...
           'rightMargin',    0.00, ...
           'bottomMargin',   0.03, ...
           'topMargin',      0.02);
       
    maxRGB = 0;
    for oiIndex = 1:numel(theOIsequence)
        tmp = xyz2rgb(oiGet(theOIsequence{oiIndex}, 'xyz'));
        if (maxRGB < max(tmp(:)))
            maxRGB = max(tmp(:));
        end
         oiImage{oiIndex} = tmp;
    end
    
    % Retrieve the eye movement sequence
    eyeMovementSequence = theConeMosaic.emPositions;
    
    for oiIndex = 1:numel(theOIsequence)
        pos = oiGet(theOIsequence{oiIndex}, 'spatial support', 'microns');
        oiXaxis = pos(1,:,1); oiYaxis = pos(:,1,2);
        r = floor((oiIndex-1)/plotCols)+1;
        c = mod((oiIndex-1), plotCols)+1;
        subplot('Position', subplotPosVectors(r,c).v);
        
        % Plot the OI
        imagesc(oiXaxis, oiYaxis, oiImage{oiIndex}/maxRGB);
        % Overlay the eye movements up to this point
        hold on;
        idx = find(absorptionsTimeAxis < oiTimeAxis(oiIndex));
        plot(eyeMovementSequence(idx,1)*theConeMosaic.pigment.width*1e6, eyeMovementSequence(idx,2)*theConeMosaic.pigment.width*1e6, 'ks-', 'LineWidth', 1.5, 'MarkerFaceColor', [0.3 0.3 0.3]);
        if (oiIndex < numel(theOIsequence))
            idx = find((absorptionsTimeAxis>=oiTimeAxis(oiIndex)) & (absorptionsTimeAxis<oiTimeAxis(oiIndex+1)));
        else
            idx = find((absorptionsTimeAxis>=oiTimeAxis(oiIndex)));
        end
        % Emphasize in red, the eye movements for the current framer
        plot(eyeMovementSequence(idx,1)*theConeMosaic.pigment.width*1e6, eyeMovementSequence(idx,2)*theConeMosaic.pigment.width*1e6, 'rs-', 'LineWidth', 1.5, 'MarkerFaceColor', [1.0 0.5 0.5]);
        
        % overlay the cone mosaic
        if (oiIndex == 1)
            plot(theConeMosaic.coneLocs(:,1)*1e6, theConeMosaic.coneLocs(:,2)*1e6, 'k.');
        end
        
        axis 'image'; axis 'xy';
        set(gca, 'CLim', [0 1], 'FontSize', 14);
        if ~((r == plotRows) && (c == 1))
            set(gca, 'XTick', [], 'YTick', []);
        end
        title(sprintf('t: %2.1f msec', 1000*oiTimeAxis(oiIndex)), 'FontSize', 14);
    end
    
    % Plot time-series responses
    set(tabGroup, 'SelectedTab',timeSeriesTab);
    axes('parent',timeSeriesTab);
    
    %% Plot the photon rate at the center of the optical image
    subplot('Position', [0.03 0.07 0.18 0.89]);
    oiWavelengthAxis = oiGet(theOIsequence{1}, 'wave');
    referencePositionOpticalImagePhotons = zeros(numel(oiWavelengthAxis), numel(theOIsequence));
    for oiIndex = 1:numel(theOIsequence)
        retinalPhotonsAtCurrentFrame = oiGet(theOIsequence{oiIndex}, 'photons');
        refRow = round(size(retinalPhotonsAtCurrentFrame,1)/2);
        refCol = round(size(retinalPhotonsAtCurrentFrame,2)/2);
        referencePositionOpticalImagePhotons(:, oiIndex) = squeeze(retinalPhotonsAtCurrentFrame(refRow, refCol, :));
    end
    hP = pcolor(oiTimeAxis, oiWavelengthAxis, referencePositionOpticalImagePhotons);
    set(hP, 'EdgeColor', 'none');
    hold on;
    % Plot the total photons (summed across all wavelengths)
    totalPhotons = sum(referencePositionOpticalImagePhotons,1);
    totalPhotonsNorm = oiWavelengthAxis(1) + (oiWavelengthAxis(end)-oiWavelengthAxis(1))*(totalPhotons-min(totalPhotons))/(max(totalPhotons)-min(totalPhotons));
    stairs(oiTimeAxis, totalPhotonsNorm, 'c-', 'LineWidth', 2.0);
    plotStimulusTimes([min(totalPhotonsNorm) max(totalPhotonsNorm)]);
    
    hold off; box on
    set(gca, 'YLim', [oiWavelengthAxis(1) oiWavelengthAxis(end)], 'XLim', [oiTimeAxis(1) oiTimeAxis(end)], 'FontSize', 14);
    xlabel('time (seconds)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('wavelength (nm)', 'FontSize', 14, 'FontWeight', 'bold');
    title('optical image photon rate (image center)', 'FontSize', 14);
    hC = colorbar('Location', 'NorthOutside', 'parent', timeSeriesTab);
    hC.FontSize =  14;
    hC.Label.String = 'photons/sec';
    axis 'xy'
    colormap(gray(1024));

    %% Plot the eye movement sequence (different colors for different OIs)
    subplot('Position', [0.25 0.07 0.22 0.89]); hold on;
    eyeMovementRange = [-100 100];

    plot(absorptionsTimeAxis, eyeMovementSequence(:,1)*theConeMosaic.pigment.width*1e6, '.', 'MarkerSize', 15, 'Color', 'r');
    hold on;
    plot(absorptionsTimeAxis, eyeMovementSequence(:,2)*theConeMosaic.pigment.height*1e6, '.', 'MarkerSize', 15, 'Color', 'b');
    plotStimulusTimes(eyeMovementRange);
    
    box on
    set(gca, 'YLim', [eyeMovementRange(1) eyeMovementRange(end)], 'XLim', [oiTimeAxis(1) oiTimeAxis(end)], 'FontSize', 14);
    legend({'eye position (X)', 'eye position (Y)'});
    ylabel('X,Y eye position (microns)', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('time (seconds)', 'FontSize', 14, 'FontWeight', 'bold');
    title('X,Y eye movements', 'FontSize', 14);
    
    
    %% Plot the LMS isomerizations
    if (theConeMosaic.rows ==1) && (theConeMosaic.cols == 3)
       referenceConeRows = [1 1 1]; referenceConeCols = [1 2 3];
    else
       % Find the (row,col) coords of the center-most L, M and S-cone
       for k = 1:3
            coneIndices = find(theConeMosaic.pattern == k+1); 
            [~, idx] = min(sum((theConeMosaic.coneLocs(coneIndices,:)).^2, 2));
            [referenceConeRows(k), referenceConeCols(k)] = ind2sub(size(theConeMosaic.pattern), coneIndices(idx));
       end
    end
    subplot('Position', [0.50 0.07 0.22 0.89]);
    isomerizationRange = [min(isomerizationRateSequence(:)) 1.05*max(isomerizationRateSequence(:))];
    hold  on
    coneColors = [1 0 0; 0 1 0; 0 0 1];
    for k = 1:3
        plot(absorptionsTimeAxis, squeeze(isomerizationRateSequence(referenceConeRows(k),referenceConeCols(k),:)), '.', 'Color', squeeze(coneColors(k,:)), 'MarkerSize', 15, 'LineWidth', 1.5);
    end
    plotStimulusTimes(isomerizationRange);
    
    hold off;
    set(gca, 'YLim', isomerizationRange, 'XLim', [oiTimeAxis(1) oiTimeAxis(end)], 'FontSize', 14);
    ylabel('isomerization rate (R*/cone/sec)', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('time (seconds)', 'FontSize', 14, 'FontWeight', 'bold');
    title('L,M,S-cone isomerization rates', 'FontSize', 14);

    %% Plot the photocurrents
    subplot('Position', [0.75 0.07 0.22 0.89]);
    photoCurrentRange = [min(photoCurrentSequence(:)) max(photoCurrentSequence(:))+2];
    hold on;
    for k = 1:3
        plot(responseTimeAxis, squeeze(photoCurrentSequence(referenceConeRows(k),referenceConeCols(k),:)), 'k.', 'Color', squeeze(coneColors(k,:)), 'MarkerSize', 15, 'LineWidth', 1.5);
    end
    plotStimulusTimes(photoCurrentRange);
    
    hold off;
    set(gca, 'XLim', [oiTimeAxis(1) oiTimeAxis(end)], 'YLim', photoCurrentRange, 'FontSize', 14);
    ylabel('photocurrent (pA)', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('time (seconds)', 'FontSize', 14, 'FontWeight', 'bold');
    title('@osLinear response', 'FontSize', 14);
    
    % Switch to eye movements tab
    set(tabGroup, 'SelectedTab',eyeMovementsTab);
    
    drawnow
    
    function plotStimulusTimes(signalRange)
        % Plot lines demarkating each OI time duration
        for oiIndex = 1:numel(theOIsequence)
            plot(oiTimeAxis(oiIndex)*[1 1], signalRange, 'k-');
        end
        % Plot the origin in magenta
        plot([0 0], signalRange, '-', 'Color', [0.7 0.1 0.3], 'LineWidth', 2);
    end

end