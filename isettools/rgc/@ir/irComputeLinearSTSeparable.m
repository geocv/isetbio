function [ir, nTrialsLinearResponse] = irComputeLinearSTSeparable(ir, bp, varargin)
% IRCOMPUTELINEARSTSEPARABLE - Computes the RGC mosaic linear response
%
%   ir = irComputeLinearSTSeparable(ir, input, 'bipolarTrials', bpTrials)
%
% The linear responses for each mosaic are computed. The linear computation
% is always space-time separation for each mosaic.  The spatial
% computationa, however, is not a convolution because the RF of the cells
% in each mosaic differ.
%
% There are two types of possible input objects.
%
% Required inputs
%   ir:      An inner retina object with RGC mosaics
%   bp:      A bipolar cell mosaic object.
%
% Optional inputs
%  bipolarTrials:  Multiple bipolar trials can be sent in using this
%                  variable.
%
% Computational questions
%    * Why do we scale the bipolar voltage input with ieContrast?
%    * Why is the RGC impulse response set to an impulse?  I gather this is
%    because the photocurrent*bipolar equals the observed RGC impulse
%    response?
%
% Computation
%
%  For each mosaic, the center and surround RF responses are calculated
%  (matrix multiply). then the temporal impulse response for the center and
%  surround is calculated.  This continuous operation produces the 'linear'
%  RGC response shown in the window.
%
%  The linear response is the input to irComputeSpikes.
%
%   rgcGLM model: The spikes are computed using the recursive influence of
%   the post-spike and coupling filters between the nonlinear responses of
%   other cells. These computations are carried in irComputeSpikes out
%   using code from Pillow, Shlens, Paninski, Sher, Litke, Chichilnisky,
%   Simoncelli, Nature, 2008, licensed for modification,
%   which can be found at
%
%            http://pillowlab.princeton.edu/code_GLM.html
%
% Outputs: 
%   The linear response and spikes are attached to the inner retina
%   mosaics.  
%
% Examples:
%
%   ir.compute(identityOS);
%
% See also: rgcGLM/rgcCompute, s_vaRGC in WL/WLVernierAcuity
%
% JRG (c) Isetbio team, 2016

%% Check inputs

p = inputParser;
p.CaseSensitive = false;

% ir and bp are both required
p.addRequired('ir',@(x) isequal(class(x),'ir')||isequal(class(x),'irPhys'));

vFunc = @(x)(isequal(class(x),'bipolar')||isequal(class(x{1}),'bipolar'));
p.addRequired('bp',vFunc);

% We can use multiple bipolar trials as input
p.addParameter('bipolarTrials',  [], @(x) isnumeric(x)||iscell(x));

p.parse(ir,bp,varargin{:});

bipolarTrials = p.Results.bipolarTrials;
nTrials = 1;
if ~isempty(bipolarTrials), 
    if length(bp)==1
        nTrials = size(bipolarTrials,1); 
    else
        nTrials = size(bipolarTrials{1},1); 
    end
end
        

%% Process the bipolar data

for iTrial = 1:nTrials
    
    % Looping over the rgc mosaics
    for rgcType = 1:length(ir.mosaic)        
        
        % Get the bipolar input data, handle bp mosaic and nTrials cases
        if length(bp) == 1
            if ~isempty(bipolarTrials)
                stim   = squeeze(bipolarTrials(iTrial,:,:,:));
            else
                stim   = bp.get('response');
            end
        else
            if ~isempty(bipolarTrials)
                stim   = squeeze(bipolarTrials{rgcType}(iTrial,:,:,:));
            else
                stim   = bp{rgcType}.get('response');
            end;
        end
        
        % JRG removes the mean and uses a contrast (or scaled contrast) as
        % the linear input.  Let's justify or explain or something.
        switch class(ir.mosaic{rgcType})
            case 'rgcPhys'
                % Let's get rid of this parameter.  Or explain.  Or
                % something.
                magFactor = 7.9; % due to bipolar filter
                stim = magFactor*ieContrast(stim);
            otherwise
                stim = ieContrast(stim);
        end
        % ieMovie(stim);
        
        % Set the rgc impulse response to an impulse 
        % When we feed a bipolar object into the inner retina, we don't
        % need to do temporal convolution. We have the tCenter and
        % tSurround properties for the rgcMosaic, so we set them to an
        % impulse to remind us that the temporal repsonse is already
        % computed.
        ir.mosaic{rgcType}=ir.mosaic{rgcType}.set('tCenter all', 1);
        ir.mosaic{rgcType}=ir.mosaic{rgcType}.set('tSurround all',1);
        
        % We use a separable space-time receptive field.  This allows
        % us to compute for space first and then time. Space. 
        [respC, respS] = rgcSpaceDot(ir.mosaic{rgcType}, stim);
        % ieMovie(respC);
        
        % Convolve with the temporal impulse response
        % If the temporal IR is an impulse, we don't need to do the
        % temporal convolution.  I'm leaving this here as a reminder that
        % we need to do this if we run any of EJ's original GLM models
        % (image -> spikes with no cone mosaic or bipolar).
        % if ir.mosaic{rgcType}.tCenter{1,1} ~= 1
        %     respC = timeConvolve(ir.mosaic{rgcType}, respC, 'c');
        %     respS = timeConvolve(ir.mosaic{rgcType}, respS, 's');
        % end
        % ieMovie(respC - respS);
        
        % Deal with multiple trial issues
        if ~isempty(bipolarTrials)
%             if length(bp) == 1
%                 if iTrial == 1
%                     nTrialsLinearResponse = zeros([nTrials,size(respC)]);
%                 end
%                 nTrialsLinearResponse(iTrial,:,:,:) =  respC - respS;
%             else
                
                if iTrial == 1
                    nTrialsLinearResponse{rgcType} = zeros([nTrials,size(respC)]);
                end
                nTrialsLinearResponse{rgcType}(iTrial,:,:,:) =  respC - respS;
%             end
        end
        
        % Store the last trial
        if iTrial == nTrials
            % Store the linear response
            ir.mosaic{rgcType} = mosaicSet(ir.mosaic{rgcType},'response linear', respC - respS);
        end
    end
end
