function [bezierPts, t, intervals,intervals_] = fitBezierWithContinuity(skelEdges, A_parameter)
% FITBEZIERWITHCONTINUITY Fits quadratic Bézier curves to a sequence of 3D skeleton points.
%
% Inputs:
%   skelEdges    - [N x 4] matrix of skeleton points (x, y, z, node index)
%   A_parameter  - struct with field 'IntervalSize_Bezier' defining points per Bézier segment
%
% Outputs:
%   bezierPts    - [numSegments*3 x 3] final Bézier control points (with C¹ continuity)
%   t            - [numPoints x 1] cumulative distance parameterization
%   intervals    - [numSegments+1 x 1] interval indices mapping points to segments

    % --- Extract 3D coordinates and transpose to 3 x N format
    l = skelEdges(:, 1:3)';
    nNodes = size(l, 2); % Number of 3D points

    % --- Define intervals: number of Bézier curves
    nIntervals = ceil(nNodes / A_parameter.bezier_interval_mm) + 1;
    intervals_ = ceil(linspace(1, nNodes, nIntervals));

    % --- Rebuild point list with additional points between segments
    l_new = zeros(size(l, 1), size(l, 2) + nIntervals - 2);
    a = 0;
    for i = 2:length(intervals_)
        temp = l(:, intervals_(i-1):intervals_(i));
        l_new(:, a+1:a+size(temp,2)) = temp;
        a = a + size(temp,2);
    end

    % --- Update interval indices to match new point structure
    r = intervals_(2:end);
    s = 1:length(r);
    intervals = intervals_;
    intervals(2:end) = r + s;
    l = l_new(1:3, :); % Use only x, y, z

    % --- Compute cumulative distance (used for Bézier parameter t)
    t = cumulativeDistance(l');

    % --- Determine number of Bézier segments
    numSegments = length(intervals) - 1;

    % --- Construct design matrix A for least squares Bézier fitting
    num_parameters = size(l, 1) * 3 * numSegments; % 3 control points per segment
    [A] = getDesignmatrix(num_parameters, l, numSegments, intervals);

    % --- Observation weight matrix
    S_ll = spdiags(ones(numel(l), 1), 0, numel(l), numel(l));
    sigma_0 = mean(diag(S_ll));
    Q_ll = S_ll / sigma_0;

    % --- Solve least squares system
    N = A' * (Q_ll \ A);
    n = A' * (Q_ll \ l(:));
    x1 = N \ n;
    Q_xx = inv(N);

    % --- Bézier control points before applying C¹ continuity
    bezierPts_A = reshape(x1, 3, 3 * numSegments)';

    % --- Apply C¹ continuity constraints
    [B] = getRestrictionsmatrix(numSegments, num_parameters, intervals);
    res = -Q_xx * B * ((B' * Q_xx * B) \ (B' * x1));
    x2 = x1 + res;

    % --- Final Bézier control points
    bezierPts = reshape(x2, 3, 3 * numSegments)';
end
