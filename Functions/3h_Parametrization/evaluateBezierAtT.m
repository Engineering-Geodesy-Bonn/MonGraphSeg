function t_xyz_adj = evaluateBezierAtT(bezierPts, intervals, t)
% EVALUATEBEZIERATT Evaluates quadratic Bézier curves at arbitrary parameter values t.
%
% Inputs:
%   bezierPts - [numSegments*3, 3] control points (3 per segment)
%   intervals - [numSegments+1, 1] start indices for each segment (1-based)
%   t         - [N, 1] parameter values (between 0 and 1), one per point
%
% Output:
%   t_xyz_adj - [N, 4] matrix with x, y, z coordinates and segment index

    numSegments = length(intervals) - 1;
    numPoints = length(t);
    t_xyz_adj = zeros(numPoints, 4); % [x, y, z, segment index]

    for i = 1:numSegments
        % Indices of points belonging to segment i
        idx_range = intervals(i):intervals(i+1)-1;
        
        ti = t(idx_range); % parameter values for these points
        ti = (ti-intervals(i))/(intervals(i+1)-intervals(i));
        % Bézier control points for this segment
        s = 3; % Quadratic Bézier
        idx_cp = (i-1)*s + 1 : i*s;
        P = bezierPts(idx_cp, :); % 3x3 matrix

        % Basis functions
        b0 = (1 - ti).^2;
        b1 = 2 * (1 - ti) .* ti;
        b2 = ti.^2;

        % Evaluate Bézier curve
        x_ = P(1,1)*b0 + P(2,1)*b1 + P(3,1)*b2;
        y_ = P(1,2)*b0 + P(2,2)*b1 + P(3,2)*b2;
        z_ = P(1,3)*b0 + P(2,3)*b1 + P(3,3)*b2;

        % Store result
        t_xyz_adj(idx_range, :) = [x_, y_, z_, i * ones(length(idx_range),1)];
    end
end
