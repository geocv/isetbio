function [recipe, sceneUnits, workingDir, origPath] = ...
    loadPbrtScene(pbrtFile, se_p, varargin)
% Setup a PBRT scene given it's name or file location. Primarily includes the
% following steps:
%   1. Check if we're given a pbrt file or a scene name.
%       a) If a pbrt file, read it, and return a recipe
%       b) If a scene name, download it from the RDT, read it, and return a
%          recipe.
%   2. Set up a working folder derived from the scene name. Copy all
%       necessary files over to the newly created working directory.
%   3. Apply any adjustable parameters given by the user to the recipe,
%       e.g. moving a planar target a certain distance away.
% TODO: I'd like to keep splitting up the above steps into more functions
% to neaten things up.
%
% Syntax:
%   [recipe sceneUnits] = selectPbrtScene(sceneName, varargin)
%
% Description:
%    The user can call sceneEye with the name of a scene to automatically
%    load it. To remove bloat from the actual sceneEye class, we will do
%    that parsing/selection in this function instead.
%
% Inputs:
%    sceneName - either a scene name like "slantedBar" or an actual pbrt
%                filepath like ("xxx.pbrt")
%    se_p - inputParser from sceneEye needs to be passed in so we can find
%                  certain parameters (e.g. planeDistance) when setting up
%                  the scene.
%    varargin  - An optional length of key/value pairs describing the scene
%
% Outputs:
%    recipe  - recipe of selected scene after adjustment parameters are
%              applied.
%    sceneUnits - some scenes are in meters and some are in millimeters.
%                 There is a flag in the sceneEye class to specify this and
%                 render appropriately.
%    workingDir - a created working directory derived from the scene name.
%    origPath - the original path to the pbrt file 
%
% History:
%    5/25/18  TL   Created
%
% TODO:
%       - There should be an easy way to list all the scenes available.

%% Parse inputs
p = inputParser;
p.addRequired('pbrtFile', @ischar);
p.parse(pbrtFile, varargin{:});

%% Check if we've been given a sceneName or a pbrt file.
[~, sceneName, ext] = fileparts(pbrtFile);
if(isempty(ext))
    % scene name
    sceneNameFlag = true;
else
    % pbrt file
    sceneNameFlag = false;
    scenePath = pbrtFile;
end

%% Load the scene

if(sceneNameFlag)
    % The user has given us a scene name and not a full pbrt
    % file. Let's find or download the right file.
    
    switch sceneName
        
        case('numbersAtDepth')
            
            scenePath = fullfile(piRootPath, 'data', ...
                'V3','NumbersAtDepth', 'numbersAtDepth.pbrt');
            sceneUnits = 'm';
            
            % Download from RDT
            if(~exist(scenePath,'file'))
                piPBRTFetch('NumbersAtDepth','deletezip',true,...
                    'pbrtversion',3,...
                    'destination folder',fullfile(piRootPath,'data','V3'));
                % Check if file exists
                if(~exist(scenePath,'file'))
                    error('Something went wrong when downloading the scene.')
                else
                    % Success!
                    fprintf('PBRT scene downloaded! File is located at: %s \n',scenePath);
                end
                
            else
                fprintf('Scene already exists in data folder. Skipping download.\n');
            end
            
        case('slantedBar')
            scenePath = fullfile(piRootPath, 'data', ...
                'V3','SlantedBar', 'slantedBar.pbrt');
            sceneUnits = 'm';
            
        case('chessSet')

            scenePath = fullfile(piRootPath,'data',...
                'V3','ChessSet','chessSet.pbrt');
            sceneUnits = 'm';
            
            % Download from RDT
            if(~exist(scenePath,'file'))
                piPBRTFetch('ChessSet','deletezip',true,...                    
                    'pbrtversion',3,...
                    'destination folder',fullfile(piRootPath,'data','V3'));
                % Check if file exists
                if(~exist(scenePath,'file'))
                    error('Something went wrong when downloading the scene.')
                else
                    % Success!
                    fprintf('PBRT scene downloaded! File is located at: %s \n',scenePath);
                end

            else
                fprintf('Scene already exists in data folder. Skipping download.\n');
            end
            
            
        case('chessSetScaled')
            
            scenePath = fullfile(piRootPath,'data','V3',...
                'ChessSetScaled','chessSetScaled.pbrt');
            sceneUnits = 'm';
            
            % Download from RDT
            if(~exist(scenePath,'file'))
                piPBRTFetch('ChessSetScaled','deletezip',true,...                    
                    'pbrtversion',3,...
                    'destination folder',fullfile(piRootPath,'data','V3'));
                % Check if file exists
                if(~exist(scenePath,'file'))
                    error('Something went wrong when downloading the scene.')
                else
                    % Success!
                    fprintf('PBRT scene downloaded! File is located at: %s \n',scenePath);
                end

            else
                fprintf('Scene already exists in data folder. Skipping download.\n');
            end

            
        case('texturedPlane')
            scenePath = fullfile(piRootPath, 'data', ...
                'V3','texturedPlane', 'texturedPlane.pbrt');
            sceneUnits = 'm';
            
        case('pointSource')
            scenePath = fullfile(piRootPath,'data',...
                'SimplePoint','simplePointV3.pbrt');
            sceneUnits = 'm';
            
        otherwise
            error('Did not recognize scene type.');
    end
    
end

%% Read the filename and get a recipe
recipe = piRead(scenePath,'version',3);
recipe.inputFile = scenePath;

%% Setup the working folder
if(isempty(se_p.Results.workingDirectory))
    % Determine scene folder name from scene path
    [path, ~, ~] = fileparts(scenePath);
    [~, sceneFolder] = fileparts(path);
    workingDir = fullfile(...
        isetbioRootPath, 'local', sceneFolder);
else
    workingDir = p.Results.workingDirectory;
end

% Copy contents of the working folder over to the local folder.
origPath = createWorkingFolder(...
    scenePath, 'workingDir', workingDir);
            
%% Make adjustments to the recipe
% E.g. move the plane to a certain distance
if(sceneNameFlag)
    
    switch sceneName
        
        case('slantedBar')
            recipe = piObjectTransform(recipe, 'SlantedBar', ...
                'Translate', [0 0 se_p.Results.planeDistance]);
            
        case('pointSource')
            % Clear previous transforms
            piClearObjectTransforms(recipe,'Point');
            piClearObjectTransforms(recipe,'Plane');
            % Add given transforms
            recipe = piObjectTransform(recipe,'Point','Scale',[se_p.Results.pointDiameter se_p.Results.pointDiameter 1]);
            recipe = piObjectTransform(recipe,'Point','Translate',[0 0 se_p.Results.pointDistance]);
            % Make it large!
            recipe = piObjectTransform(recipe,'Plane','Scale',[se_p.Results.pointDistance*10 se_p.Results.pointDistance*10 1]);
            % Move it slightly beyond the point
            recipe = piObjectTransform(recipe,'Plane','Translate',[0 0 se_p.Results.pointDistance+0.5]);
            
        case('texturedPlane')
            % Scale and translate
            planeSize = se_p.Results.planeSize;
            scaling = [planeSize(1) planeSize(2) 1] ./ [1 1 1];
            recipe = piObjectTransform(recipe, 'Plane', 'Scale', scaling);
            recipe = piObjectTransform(recipe, 'Plane', ...
                'Translate', [0 0 se_p.Results.planeDistance]);
            % Texture
            [pathTex, nameTex, extTex] = fileparts(se_p.Results.planeTexture);
            copyfile(se_p.Results.planeTexture, workingDir);
            if(isempty(pathTex))
                error('Image texture must be an absolute path.');
            end
            recipe = piWorldFindAndReplace(recipe, 'dummyTexture.exr', ...
                strcat(nameTex, extTex));
    end
end
