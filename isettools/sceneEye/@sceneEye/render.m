function [ieObject, terminalOutput, scaleFactor] = render(obj, varargin)
% Render a scene3D object and return an optical image.
%
% Syntax:
%   [ieObject, terminalOutput, outputFile] = render(obj, [varargin])
%
% Description:
%	 Given a scene3D object, we have all the information we need to
%    construct a PBRT file and render it. Therefore, this function does the
%    following:
%       1. Write out a new PBRT ([renderName].pbrt) in working directory
%       2. Render using docker container
%       3. Load the output into an ISETBIO optical image, filling in the
%          right parameters with the scene information
%       4. Return the OI
%
% Inputs:
%    obj            - The scene3D object to render
%    varargin       - (Optional) Other key/value pair arguments
%
% Outputs:
%    ieObject       - The Optical Image object
%    terminalOutput - Terminal output
%

%% Write out into a pbrt file
objNew = obj.write();
recipe = objNew.recipe; % Update the recipe within the sceneEye object. 

%% Render the pbrt file using docker
%scaleFactor = [];
[ieObject, terminalOutput,scaleFactor] = piRender(recipe,'version',3,...
    'scaleFactor',1);
        
%% Set OI parameters correctly:
if(~obj.debugMode)
    ieObject = obj.setOI(ieObject);
end

end
