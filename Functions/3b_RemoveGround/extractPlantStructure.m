function [overallEdges_plant, skel_points_plant,plantStartingNodes,ground_existing] = extractPlantStructure(updated_neighbors, updated_skeleton_points, overallEdges, A_parameter)
%EXTRACTPLANTSTRUCTURE Removes the overallEdges that belong to the ground 
%
% Inputs:
%   updated_neighbors      - NxK matrix where each row lists a node and its neighbors
%   updated_skeleton_points - Nx4 matrix with [x,y,z,ID] of each skeleton point
%   overallEdges           - Cell array of edge data {nodeIDs, startIdx, endIdx}
%   A_parameter            - Parameter passed to the branching detection function
%
% Outputs:
%   overallEdges_plant     - Filtered list of edges representing only the
%   plant edges
%   skel_points_plant      - Filtered skeleton points (without ground)

    % Step 1: Generate edge list from neighbor matrix
    edges_list = generateEdgeListFromNeighbors(updated_neighbors);

    % Step 2: Create graph from edges and assign 3D coordinates to nodes
    graph_A = graph(edges_list(:,1),edges_list(:,2));
    graph_A.Nodes.Coordinates = updated_skeleton_points;

  
    % Step 3: Detect branching point and compute height threshold
    [branching_point, height_threshold, min_branching] = ...
        computeBranchingAndThreshold(graph_A, overallEdges, updated_skeleton_points, A_parameter);

     % Step 4: Remove ground-level parts of the graph to isolate the plant   
    [overallEdges_plant, skel_points_plant,plantStartingNodes,ground_existing] = ...
        removeGroundNodesFromGraph(overallEdges, updated_skeleton_points, branching_point, min_branching, height_threshold);

end
