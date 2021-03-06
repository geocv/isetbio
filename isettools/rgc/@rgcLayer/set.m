function obj = set(obj, param, val, varargin)
% rgcSet: a method of @rgc that sets rgc object 
% parameters using the input parser structure.
% 
%       val = @rgcLayer.set(ir, param, value, varargin)
% 
% Inputs: RGC layer object
% 
% Properties:
%     name: type of rgc object, e.g., 'macaque RGC'
%     input: 'cone current' or 'scene RGB', depends on type of outer
%           segment object created.
%     temporalEquivEcc: the temporal equivalent eccentricity, used to 
%             determine the size of spatial receptive fields.   
%     mosaic: contains rgcMosaic objects for the five most common types
%           of RGCs: onParasol, offParasol, onMidget, offMidget,
%           smallBistratified.
%     numberTrials: the number of trials for spiking models LNP and GLM
% 
% Example:
%   rgc1 = rgcSet(rgc1, 'name', 'macaque RGC')
%   rgc1 = rgcSet(rgc1, 'temporalEquivEcc', 5)
% 
% 9/2015 JRG 

%% Parse

p = inputParser; 
p.CaseSensitive = false; 
p.FunctionName = mfilename;

% Make key properties that can be set required arguments, and require
% values along with key names.
allowableFieldsToSet = {...   
        'name',...
        'input',...
        'temporalEquivEcc',... 
        'timing',...
        'spacing',...
        'mosaic',...
        'numberTrials',...
        'recordedSpikes'...
        'numbertrials',...
        'ntrials'
    };
p.addRequired('param',@(x) any(validatestring(x,allowableFieldsToSet)));
p.addRequired('val');
p.addParameter('nMosaic',[],@isscalar);

% Parse and put results into structure p.
p.parse(param,val,varargin{:}); 
param = ieParamFormat(p.Results.param);
val   = p.Results.val;


%% Set key-value pairs.
switch param
        
    case{'name'}
        obj.name = val;
    case{'input'}
        obj.input = val;
    case{'temporalequivecc'}        
        obj.temporalEquivEcc = val;
    case{'mosaic'}
        % set('mosaic',val,'nMosaic',integer);
        %
        nMosaic = p.Results.nMosaic;
        if isempty(nMosaic),  obj.mosaic{end+1} = val;
        else,                 obj.mosaic{nMosaic} = val;
        end  
        
    case{'numbertrials','ntrials'}
        % Will be a vector some day for number of trials for each mosaic in
        % the ir.  Now, it is just a plain old number.
        obj.nTrials = val;
        
    case{'timing'}
        obj.timing = val;
    case{'spacing'} 
        obj.spacing = val;
        
    case{'recordedspikes'}
        % For Phys data into ISETBIO
        % @JRG - Comment.  Preallocate space.
        for cellind = 1:length(val)
            for iTrial = 1:length(val{1}.rasters.recorded)
                recorded_spiketimes{cellind,1,iTrial} = (val{cellind}.rasters.recorded{iTrial});
            end
        end
        
        if isa(obj.mosaic{1},'rgcPhys')
            obj.mosaic{1} = mosaicSet(obj.mosaic{1},'responseSpikes',recorded_spiketimes);
        end
end

end

