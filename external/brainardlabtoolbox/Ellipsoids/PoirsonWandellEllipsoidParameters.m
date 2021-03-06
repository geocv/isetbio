function [A,Ainv,Q,theBgLMS] = PoirsonWandellEllipsoidParameters(conditionStr,sf)
% [A,Ainv,Q,theBgLMS] = PoirsonWandellEllipsoidParemeters(conidtionStr)
%
% Return the parameters in cone contrast space of the threshold ellipsoid
% predicted by the Poirson-Wandell model.
%    Poirson AB, Wandell BA. 1996. Pattern-color separable pathways predict
%    sensitivity to simple colored patterns Vision Res 36: 515-26.
%
% The paper is a little unclear about the units of the color matrix, but by
% inference the transformation seems to be in cone excitation rather than 
% cone contrast coordinates.  Thus the ellipsoids generated by the
% parameters need to be divided by the background cone excitations to get
% ellipsoids in cone contrast coordinates.  
%
% 6/29/16  dhb  Wrote it.

%% Get parameters from paper Tables 1 and 2
%
% These give the model parameters for each of the three subject/condition
% combinations measured.
switch (conditionStr)
    case 'HT,cc'
        % Subject HT, constant cycles stimulus as sf varies
        MConesToOpponent = [0.759 0.649 0.058 ; -0.653 0.756 0.033 ; -0.159 -0.414 0.896];
        theSfs = [0.5 1 2 4]';
        theFactors = [0.753 8.732 4.075 ;
            1.226 8.044 2.567 ;
            0.864 5.435 1.187 ;
            0.683 2.536 0.266];
        theBgLMS = [82.87 65.45 25.80]';
        
    case 'HT,cs'
        % Subject HT, constant size stimulus as sf varies
        MConesToOpponent = [-0.246 0.967 -0.072 ; -0.698 0.716 -0.005 ; 0.165 -0.599 -0.784];
        theSfs = [0.5 1 2 4 8]';
        theFactors = [11.864 63.945 8.080 ;
            18.037 74.214 7.212 ;
            23.739 60.598 3.235 ;
            28.354 31.746 3.379 ;
            26.959 12.302 2.622];
        theBgLMS = [7.67 7.20 6.31]';
        
    case 'LW,cs'
        % Subject LW, constant size stimulus as sf varies
        MConesToOpponent = [0.717 0.677 -0.164 ; -0.670 0.742 -0.029 ; 0.199 -0.682 0.703];
        theSfs = [0.5 1 2 4 8]';
        theFactors = [4.981 60.556 6.575 ; ...
            6.406 53.460 5.390 ; ...
            11.081 36.944 3.785 ; ...
            12.354 24.390 2.747 ; ...
            9.550 19.513 3.706];
        theBgLMS = [7.67 7.20 6.31]';
        
    otherwise
        error('Unknown condition string entered')
end

index = find(theSfs == sf);
if (isempty(index))
    error('No data at specified spatial frequency');
end
    
A = diag(theFactors(index,:))*MConesToOpponent;
Ainv = inv(A);
Q = A'*A;