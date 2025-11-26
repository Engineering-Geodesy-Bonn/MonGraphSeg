function [B] = getRestrictionsmatrix(numSegments, numParam, intervals)
% getRestriktionsmatrix: Builds the constraint matrix B to enforce C0 and C1 continuity
% across Bézier segments.
%
% Inputs:
%   numSegments - Number of Bézier segments
%   numParam    - Total number of parameters (3 × (2+1) × numSegments)
%   intervals   - Index boundaries of original input points
%
% Output:
%   B           - Sparse constraint matrix for enforcing continuity

% Number of transition points between segments (i.e., where constraints are applied)
numTransitions = numSegments - 1;
r = 2 + 1;                          % Number of control points per segment
paramsPerSegment = 3 * r;          % Parameters per segment
constraintsPerTransition = 6;        % 3 for C0 + 3 for C1 continuity

% Initialize full constraint matrix
B = zeros(numParam, numTransitions * constraintsPerTransition);

for i = 1:numTransitions
    % --- C0 Continuity (position)
    % Match last control point of segment i with first control point of segment i+1

    % Rows (global parameter indices) for control point at end of segment i
    row_c0_1 = paramsPerSegment * (i-1) + (r-1)*3 + 1 : paramsPerSegment * (i-1) + r*3;

    % Rows for first control point of next segment
    row_c0_2 = paramsPerSegment * i + 1 : paramsPerSegment * i + 3;

    % Columns for C0 constraints
    col_c0 = (i-1) * constraintsPerTransition + 1 : (i-1) * constraintsPerTransition + 3;

    % Fill in C0 constraints
    B(sub2ind(size(B), row_c0_1, col_c0)) = 1;
    B(sub2ind(size(B), row_c0_2, col_c0)) = -1;

    % --- C1 Continuity (tangent direction)
    % Uses 3 consecutive points from intervals to estimate local lambda
    a = intervals(i);     % Start of segment i
    b = intervals(i+1);   % End of segment i (and start of segment i+1)
    c = intervals(i+2);   % End of segment i+1

    lambda = (c - a) / (b - a);  % Relative position factor

    % Rows for penultimate control point of segment i
    row_c1_1 = paramsPerSegment * (i-1) + (r-2)*3 + 1 : paramsPerSegment * (i-1) + (r-2)*3 + 3;

    % Rows for the first and second control points of segment i+1
    row_c1_2 = paramsPerSegment * i + 1         : paramsPerSegment * i + 3;
    row_c1_3 = paramsPerSegment * i + 3 + 1   : paramsPerSegment * i + 2*3;

    % Columns for C1 constraints
    col_c1 = (i-1) * constraintsPerTransition + 4 : (i-1) * constraintsPerTransition + 6;

    % Fill in C1 constraints
    B(sub2ind(size(B), row_c1_1, col_c1)) = (1 - lambda);
    B(sub2ind(size(B), row_c1_2, col_c1)) = lambda;
    B(sub2ind(size(B), row_c1_3, col_c1)) = -1;
end

% Convert to sparse for efficiency
B = sparse(B);
end
