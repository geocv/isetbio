function xyz = srgb2xyz(srgb)
% Transform srgb to CIE XYZ
%
% Syntax:
%   xyz = srgb2xyz(srgb)
%
% Description:
%    Convert sRGB image into CIE XYZ values. The input range for srgb
%    values is (0, 1).
%
% Inputs:
%    sRGB - Standard Red-Green-Blue format image
%
% Outputs:
%    xyz  - CIE XYZ format image
%
% References:
%    <http://en.wikipedia.org/wiki/SRGB>
%

% History:
%    xx/xx/03       Copyright ImagEval Consultants, LLC.
%    11/01/17  jnm  Comments & formatting

% Examples:
%{
   ptbSRGBs = [[188 188 188]' [124 218 89]' [255 149 203]' [255 3 203]'];
   % The ISET form takes the frame buffer values in the [0, 1] regime
   isetSRGBs = ptbSRGBs / 255;
   isetSRGBs = XW2RGBFormat(isetSRGBs', 4, 1);
   isetXYZ   = srgb2xyz(isetSRGBs);
%}

% Data format should be in RGB format
if ndims(srgb) ~= 3
    error(['srgb2xyz:  srgb must be a NxMx3 color image. '
        'Use XW2RGBFormat if needed.']);
end

% Convert the srgb values to the linear form in the range (0,1)
lrgb = srgb2lrgb(srgb);  %imtool(lrgb/max(lrgb(:)))

% convert lrgb to xyz 
matrix = colorTransformMatrix('lrgb2xyz');
xyz = imageLinearTransform(lrgb, matrix);  

end
