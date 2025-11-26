function [overallEdges_plant, skel_points_plant, plantStartingNodes, ground_existing] = removeGroundNodesFromGraph(overallEdges, updated_skeleton_points, branching_point, min_branching, height_threshold)
% REMOVEGROUNDNODESFROMGRAPH - Filters ground-level edges and nodes from a graph.
%
% Syntax:
%   [overallEdges_plant, skel_points_plant, plantStartingNodes, ground_existing] = removeGroundNodesFromGraph(overallEdges, updated_skeleton_points, branching_point, min_branching, height_threshold)
%
% Inputs:
%   overallEdges            - Cell array of original edge lists.
%   updated_skeleton_points - Nx4 matrix with coordinates and node IDs.
%   branching_point         - List of node indices representing branching points.
%   min_branching           - Index of the lowest branching point.
%   height_threshold        - Z-threshold to define ground level.
%
% Outputs:
%   overallEdges_plant      - Filtered edge list representing the plant structure.
%   skel_points_plant       - Filtered skeleton points (excluding ground nodes).
%   plantStartingNodes      - Nodes serving as starting points for the plant structure.
%   ground_existing         - Boolean flag indicating whether ground nodes were detected.
%
% Description:
%   This function removes edges and nodes below a certain height threshold to clean up
%   ground structures in the graph representation. It ensures that only plant-related
%   structures remain in the skeleton.
%
% Example:
%   [edges, points, startNodes, groundFlag] = removeGroundNodesFromGraph(overallEdges, skeleton_pts, branchingPts, minBranchIdx, heightThresh);
%
% See also: graph, rmedge, conncomp, unique, ismember

    % Extract unique node IDs from edges
    unique_nodes = unique(cell2mat(overallEdges(:, 2:3)));

    % Construct graph representation
    graph_B = graph(cell2mat(overallEdges(:, 2)), cell2mat(overallEdges(:, 3)), 1:length(overallEdges(:,3)));
    graph_B.Nodes.Coordinates = updated_skeleton_points(1:unique_nodes(end), :);

    % Step 1: Identify and remove low edges connected to branching point
    edges_connected = find(sum(graph_B.Edges.EndNodes == branching_point(min_branching), 2));
    edge_heights = min([
        graph_B.Nodes.Coordinates(graph_B.Edges.EndNodes(edges_connected, 1), 3), ...
        graph_B.Nodes.Coordinates(graph_B.Edges.EndNodes(edges_connected, 2), 3)
    ], [], 2);

    removed_edges = graph_B.Edges.Weight(edges_connected(edge_heights < height_threshold), :);
    graph_B = rmedge(graph_B, edges_connected(edge_heights < height_threshold));

    % Step 2: Remove all edges entirely below the height threshold
    heights_A = graph_B.Nodes.Coordinates(graph_B.Edges.EndNodes(:, 1), 3);
    heights_B = graph_B.Nodes.Coordinates(graph_B.Edges.EndNodes(:, 2), 3);
    graph_B = rmedge(graph_B, find(max([heights_A, heights_B], [], 2) < height_threshold));

    % Step 3: Keep only the connected component that includes the branching point
    nodes_CC = conncomp(graph_B);
    edges_CC = nodes_CC(graph_B.Edges.EndNodes(:, 1));
    plant_edges = graph_B.Edges.Weight(edges_CC == nodes_CC(branching_point(min_branching)), :);
    plant_edges = [plant_edges; removed_edges];

    % Step 4: Filter and reindex skeleton points
    overallEdges_plant = overallEdges(plant_edges, :);
    skel_points_plant = updated_skeleton_points(ismember(updated_skeleton_points(:, 4), vertcat(overallEdges_plant{:, 1})), :);

    for i = 1:size(overallEdges_plant, 1)
        nodes_plant = overallEdges_plant{i, 1};
        [~, mapped_indices] = ismember(nodes_plant, skel_points_plant(:, 4));
        overallEdges_plant{i, 1} = mapped_indices;
        overallEdges_plant{i, 2} = mapped_indices(1);
        overallEdges_plant{i, 3} = mapped_indices(end);
    end

    % Step 5: Update node indices for skeleton points
    skel_points_plant(:, 4) = 1:size(skel_points_plant, 1);
    Nodes_plant = unique([cell2mat(overallEdges_plant(:, 2)); cell2mat(overallEdges_plant(:, 3))]); 
    height_nodes = skel_points_plant(Nodes_plant, 3);

    % Step 6: Determine valid plant starting nodes
    endnodes_lowEdges = Nodes_plant(height_nodes < height_threshold, :);
    plantStartingNodes = endnodes_lowEdges(endnodes_lowEdges ~= branching_point(min_branching));

    % Step 7: Check if ground elements exist in the dataset
    if height(overallEdges) == height(overallEdges_plant)
        disp("There is no ground in this dataset");
        ground_existing = false;
    else
        ground_existing = true;
    end

end
