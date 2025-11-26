function [branching_point, height_threshold, min_branching] = computeBranchingAndThreshold(graph_A, overallEdges, updated_skeleton_points, A_parameter)
%COMPUTEBRANCHINGANDTHRESHOLD Finds the first branching point and height threshold
%
% Inputs:
%   graph_A                - Unweighted graph built from neighbor edges
%   overallEdges           - Edge data
%   updated_skeleton_points - Node coordinates with ID in 4th column
%   A_parameter            - Parameter used by detectFirstBranch
%
% Outputs:
%   branching_point        - Indices of branching points
%   height_threshold       - Minimum Z-value of the branching point
%   min_branching          - Index of branching point with lowest height
%   max_point              - Node with maximum Z-coordinate (tip)

    [~, max_point] = max(graph_A.Nodes.Coordinates(:, 3));

    branching_point = detectFirstBranch(graph_A, overallEdges, updated_skeleton_points, max_point, A_parameter);
    [height_threshold, min_branching] = min(graph_A.Nodes.Coordinates(branching_point, 3));
end
