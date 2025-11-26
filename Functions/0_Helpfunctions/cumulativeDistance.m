function t = cumulativeDistance(pts)
% CUMULATIVEDISTANCE - Computes cumulative arc length along a 3D curve
%
% Syntax:
%   t = cumulativeDistance(pts)
%
% Inputs:
%   pts - (Nx3 array) 3D points representing a curve [x, y, z]
%
% Output:
%   t - (Nx1 array) Cumulative distance along the curve, starting at 0
%
% Description:
%   Calculates the cumulative Euclidean distance between consecutive points,
%   useful for curve parameterization by arc length.

    % Compute cumulative arc length between consecutive points
    t = [0; cumsum(sqrt(diff(pts(:,1)).^2 + diff(pts(:,2)).^2 + diff(pts(:,3)).^2))];
end