function [overallEdges,updated_skeleton_points,updated_neighbors] = computeInitialGraph(points_skel, options)
% COMPUTEINITIALGRAPH - Constructs an initial graph from skeleton points.
%
% Syntax:
%   overallEdges = computeInitialGraph(points_skel, options)
%
% Inputs:
%   points_skel - (Nx3 array) Skeleton points representing the graph nodes.
%   options   - Structure containing configuration settings for visualization.
%
% Outputs:
%   overallEdges - (Mx3 array) Computed edges representing connected components in the graph.
%
% Description:
%   This function builds a structured graph from the given skeleton points:
%   1. Connects each node to its k-nearest neighbors.
%   2. Cleans up unnecessary triangle connections.
%   3. Ensures all graph components are fully connected.
%   4. Sorts neighboring points to maintain structural consistency.
%   5. Removes and samples junction groups for clarity.
%   6. Traces combined edges between terminal and junction points.
%   7. Visualizes the final graph structure.
%
% Example:
%   edges = computeInitialGraph(skeletonPoints, options);
%
% See also: createGraph_knn, rmTriangles, connectGraphComponents, sortNeighbors,
%           removeConnectedGroups, traceGraphEdges, visualizeInitialGraph

    % Step 1: Connect each node to its k-nearest neighbors
    edges = createGraph_knn(points_skel);

    % Step 2: Remove unnecessary triangles to ensure nodes have 1-3 neighbors
    edges_clean = rmTriangles(edges);

    % Step 3: Ensure that all graph components are connected
    edges_clean = connectGraphComponents(points_skel, edges_clean);

    % Step 4: Sort neighbors and obtain adjacency matrix
    [neighbors_matrix, points_skel, neighbor_counts] = sortNeighbors(edges_clean, points_skel);

    % Step 5: Remove and sample connected junction groups for unbranched
    % graph structure
    [updated_skeleton_points, updated_neighbors] = removeConnectedGroups(points_skel, neighbors_matrix, neighbor_counts);

    % Step 6: Detect related edges between junction and endpoints
    overallEdges = traceGraphEdges(updated_neighbors, updated_skeleton_points);

    % Step 7: Visualize the computed graph
    visualizeInitialGraph(overallEdges, updated_skeleton_points, options);

    % Display confirmation message
    fprintf('### Initial graph computed successfully\n');

end
