function lk_werte_para = evaluateQuadraticBezierSegments(bezierPts, numSegments,temp_t)
% EVALUATEQUADRATICBEZIERSEGMENTS Evaluates a sequence of quadratic Bézier segments.
% 
%   lk_werte_para = evaluateQuadraticBezierSegments(bezierPts, numSegments, nNodes)
% 
%   Inputs:
%       bezierPts    - A matrix of control points for all segments, 
%                      with size [numSegments*3, 3]. Each row is [x, y, z].
%       numSegments  - The number of Bézier curve segments.
%       nNodes       - The number of evaluation points per segment.
%
%   Output:
%       lk_werte_para - A matrix of evaluated points with size [numSegments*nNodes, 4].
%                       Columns 1–3: evaluated x, y, z coordinates.
%                       Column 4: index of the segment the point belongs to.



    % Preallocate result matrix
    r = length(temp_t);
    s = 3; % Number of control points for a quadratic Bézier curve
    lk_werte_para = zeros(numSegments * r, s + 1); % +1 for segment index

    for i = 1:numSegments
        % Extract the 3 control points for the i-th segment
        idx_start = s * (i - 1) + 1;
        bezierPts_ = bezierPts(idx_start : idx_start + s - 1, :);

        % Basis functions for a quadratic Bézier curve
        b0 = (1 - temp_t).^2;
        b1 = 2 * (1 - temp_t) .* temp_t;
        b2 = temp_t.^2;

        % Evaluate the Bézier curve in x, y, z
        x_ = bezierPts_(1,1) * b0 + bezierPts_(2,1) * b1 + bezierPts_(3,1) * b2;
        y_ = bezierPts_(1,2) * b0 + bezierPts_(2,2) * b1 + bezierPts_(3,2) * b2;
        z_ = bezierPts_(1,3) * b0 + bezierPts_(2,3) * b1 + bezierPts_(3,3) * b2;

        % Store the evaluated points and their segment index
        row_idx = (i - 1) * r + 1;
        lk_werte_para(row_idx : row_idx + r - 1, :) = [x_', y_', z_', i * ones(r, 1)];
    end
end
