function [A] = getDesignmatrix(num_parameter, l, numSegments, intervals)
% getDesignmatrix: Constructs the design matrix A for Bézier curve fitting
%
% Inputs:
%   num_parameter - Number of unknown parameters: dim × (r+1) × numSegments
%   l             - Observations (3 × N matrix)
%   t             - Cumulative parameter (e.g., distance-based)
%   numSegments   - Number of Bézier segments
%   intervals     - Index boundaries for each segment
%
% Output:
%   A             - Sparse design matrix for least squares estimation

% Initialize full matrix
A = zeros(size(l, 2) * 3, num_parameter);
row_offset = 1;
col_offset = 1;
cols_per_segment = 3 * (2 + 1);  % Parameters per segment

for i = 1:numSegments
    % Get points for current segment
    l_i = l(:, intervals(i):intervals(i+1)-1);  % [3 × points_in_segment]
    numPts_i = size(l_i, 2);

    % Compute local lambda parameter [0,1] based on cumulative distance
    lambda = cumulativeDistance(l_i');         % [numPts_i × 1]
    lambda = lambda ./ max(lambda);            % Normalize to [0,1]

        % Quadratic Bézier basis functions
        b0 = 1 - 2*lambda + lambda.^2;
        b1 = 2*lambda - 2*lambda.^2;
        b2 = lambda.^2;

        for j = 1:numPts_i
            row_idx = 3*(j-1) + row_offset : 3*(j-1) + row_offset + 2;

            col1 = col_offset      : col_offset + 2;
            col2 = col_offset + 3  : col_offset + 5;
            col3 = col_offset + 6  : col_offset + 8;

            A(sub2ind(size(A), row_idx, col1)) = b0(j);
            A(sub2ind(size(A), row_idx, col2)) = b1(j);
            A(sub2ind(size(A), row_idx, col3)) = b2(j);
        
    end

    % Update offsets for next segment
    col_offset = col_offset + cols_per_segment;
    row_offset = row_offset + numPts_i * 3;
end

% Convert to sparse matrix to save memory
A = sparse(A);
end
