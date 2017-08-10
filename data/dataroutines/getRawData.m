function theData = getRawData(dataName,varargin)
%%getRawData  Return a struct with some raw data in it
%
% Syntax:
%    theData = getRawData(dataName);
%
% Description:
%    Return a named piece of raw data as a struct.  This routine
%    is agnostic about what is being returned, the caller has
%    to understand what to expect, given the name.
%
%    This routine takes a datatype key/value pair, which would let us
%    move the data around and get it in some other way, just by
%    changing the datatype in the caller.  The hope is that this will
%    make it easier in the future to change where data live, without
%    breaking any code that uses the data.
%
% Input:
%    dataName              A string specifying the name of the data
%
% Output:
%     theData              Struct containing the raw data.
%     wave                 Column vector of sample wavelengths, in nm
%
% Optional key/value pairs:
%     'datatype'           Type of data to be fetched.
%                            'matfileonpath' (default). The data can be obtained as theData = load(dataName), because
%                                                       the data is in a .mat file on the Matlab path.
%
% See also:

% 08/10/17  dhb  Drafted.

%% Parse inputs
p = inputParser;
p.addParameter('datatype','matfileonpath', @ischar);
p.parse(varargin{:});

%% Handle choices
switch (p.Results.datatype)
    case {'matfileonpath'}
        theData = load(dataName);
        
    otherwise
        error('Unsupported datatype specified');
end
        