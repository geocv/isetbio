% t_rgcSubunitBipolar
% 
% Demonstrates the inner retina object calculation for the subunit RGC
% model. This is an attempt to explicitly model the temporal response of
% the bipolar cells that take as input the cone outer segment current. The
% temporal response of the bipolar cell is I(t) + 0.5*I'(t), where I(t) is
% the impulse response of the linear cone outer segment. The subunit model
% as a front end to the spike generating code by Pillow et al., Nature,
% 2008.
% 
% 4/2016 BW JRG HJ (c) isetbio team
%%
clear
ieInit

%% Movie of the cone absorptions 
% % Get data from isetbio archiva server
% rd = RdtClient('isetbio');
% rd.crp('/resources/data/istim');
% a = rd.listArtifacts;
% 
% % Pull out .mat data from artifact
% whichA =1 ;
% data = rd.readArtifact(a(whichA).artifactId);
% % iStim stores the scene, oi and cone absorptions
% iStim = data.iStim;
% absorptions = iStim.absorptions;

%% Grating subunit stimulus
clear params
stimP.fov      = 1; % degrees
stimP.barWidth = 2;
stimP.nSteps   = 150;
iStim = ieStimulusGratingSubunit(stimP);
absorptions = iStim.absorptions;

%% White noise
% iStim = ieStimulusWhiteNoise;

%% Show raw stimulus for osIdentity
figure;
for frame1 = 1:size(iStim.sceneRGB,3)
    imagesc(squeeze(iStim.sceneRGB(:,:,frame1,:)));
    axis image
    pause(0.15)
    colormap gray; drawnow;
end
close;

% coneImageActivity(iStim.absorptions,'dFlag',true);

%% Outer segment calculation
% 
% Input = RGB
osLinear = osCreate('linear');

% Set size of retinal patch
patchSize = sensorGet(absorptions,'width','um');
osLinear = osSet(osLinear, 'patch size', patchSize);

% Set time step of simulation equal to absorptions
timeStep = sensorGet(absorptions,'time interval','sec');
osLinear = osSet(osLinear, 'time step', timeStep);

% Set osI data to raw pixel intensities of stimulus
% osI = osSet(osI, 'rgbData', 0.6-iStim.sceneRGB);
osLinear = osCompute(osLinear,absorptions);

% % Plot the photocurrent for a pixel
osPlot(osLinear,absorptions);

%% Plot cones
% cone_mosaic = absorptions.human.coneType;
% [xg yg] = meshgrid([1:123,1:150]);
% xg2 = xg(1:123,1:150); yg2 = yg(1:123,1:150);
% 
% figure; scatter(xg2(:),yg2(:),40,4-cone_mosaic(:),'o','filled'); colormap jet; set(gca,'color',[0 0 0])
%         

%% Build the bipolar cell filter

% osFilter = osGet(osI,'mConeFilter');
osFilter = osLinear.mConeFilter;

osFilterDerivativeShort = diff(osFilter);
% osFilterDerivative = interp1(1:length(osFilterDerivativeShort),osFilterDerivativeShort,1:length(osFilter))';
osFilterDerivative = [osFilterDerivativeShort; osFilterDerivativeShort(end)];

bipolarFilter = osFilter + .5*osFilterDerivative;

figure; 
plot(bipolarFilter);
hold on;
plot(osFilter,'g');
plot(osFilterDerivative,'r');
xlabel('Time (msec)'); ylabel('pA / (R*/sec)');
set(gca,'fontsize',16);

legend('bipolar f(t)','os f(t)','os f''(t)');

%% Filter to get bipolar cell output

eZero = -50;
hwrCurrent = ieHwrect(osLinear.coneCurrentSignal,eZero);

kernel = fspecial('gaussian',[9,9],3);

bipolar = ieSpaceTimeFilter(hwrCurrent,kernel);

strideSubsample = 4;
bipolarSubsample = ieImageSubsample(bipolar, strideSubsample);

szBS = size(bipolarSubsample);
bipolarSubsampleRS = reshape(bipolarSubsample,szBS(1)*szBS(2),szBS(3));

bipolarOutputRS = convn(bipolarSubsampleRS,bipolarFilter','full');

bipolarOutput = reshape(bipolarOutputRS,szBS(1),szBS(2),size(bipolarOutputRS,2));


%% Create outer segment displayRGB in order to pass bipolarOutput to innerRetina

% Input = RGB
osI = osCreate('displayRGB');

% Set size of retinal patch
patchSize = sensorGet(absorptions,'width','um');
osI = osSet(osI, 'patch size', patchSize);

% Set time step of simulation equal to absorptions
timeStep = sensorGet(absorptions,'time interval','sec');
osI = osSet(osI, 'time step', timeStep);

% Set osI data to raw pixel intensities of stimulus
% bipolarOutputRGB = repmat(1*ieScale(bipolarOutput)./3,[1 1 1 3]);
bipolarOutputRGB = 1000*ieScale(bipolarOutput);
% bipolarOutputRGB = (bipolarOutput);
% figure; plot(reshape(ieScale(bipolarOutput),31*38,180)')
osI = osSet(osI, 'rgbData', bipolarOutputRGB);

% osPlot(osI,iStim.absorptions);

%% Build the inner retina object

clear params innerRetina0
params.name      = 'Macaque inner retina 1'; % This instance
params.eyeSide   = 'left';   % Which eye
params.eyeRadius = 7;        % Radius in mm
params.eyeAngle  = 90;       % Polar angle in degrees

innerRetina0 = irCreate(osI, params);

% Create a coupled GLM model for the on midget ganglion cell parameters
innerRetina0.mosaicCreate('model','LNP','type','on midget');

irPlot(innerRetina0,'mosaic');

% Set subunit size
% When numberSubunits is set to the RF size, every pixel is a subunit
% This is the default, after Gollisch & Meister, 2008
sRFcenter = mosaicGet(innerRetina0.mosaic{1},'sRFcenter');
% mosaicSet(innerRetina0.mosaic{1},'numberSubunits',size(sRFcenter));

% Alternatively, have 2x2 subunits for each RGC
% mosaicSet(innerRetina0.mosaic{1},'numberSubunits',[2 2]);
%% Compute RGC mosaic responses

innerRetina0 = irCompute(innerRetina0, osI);
irPlot(innerRetina0, 'psth');
irPlot(innerRetina0, 'linear');
% irPlot(innerRetina0, 'raster');

%% Show me the PSTH for one particular cell

% irPlot(innerRetina0, 'psth response','cell',[2 2]);
% irPlot(innerRetina0, 'raster','cell',[1 1]);

%% Build the os and inner retina object

% Input = RGB
osI = osCreate('displayRGB');

% Set size of retinal patch
patchSize = sensorGet(absorptions,'width','um');
osI = osSet(osI, 'patch size', patchSize);

% Set time step of simulation equal to absorptions
timeStep = sensorGet(absorptions,'time interval','sec');
osI = osSet(osI, 'time step', timeStep);

osI = osSet(osI, 'rgbData', 2*(iStim.sceneRGB-0.5));


clear params
params.name      = 'Macaque inner retina 1'; % This instance
params.eyeSide   = 'left';   % Which eye
params.eyeRadius = 7;        % Radius in mm
params.eyeAngle  = 90;       % Polar angle in degrees

innerRetina1 = irCreate(osLinear, params);

% Create a coupled GLM model for the on midget ganglion cell parameters
innerRetina1.mosaicCreate('model','lnp','type','on midget');
irPlot(innerRetina1,'mosaic');

innerRetina1 = irCompute(innerRetina1, osI);
irPlot(innerRetina1, 'linear');
irPlot(innerRetina1, 'psth');

% params.eyeRadius = 3;        % Radius in mm
% innerRetina2 = irCreate(osLinear, params);
% innerRetina2.mosaicCreate('model','lnp','type','off midget');
% hold on;
% irPlot(innerRetina2,'mosaic');
