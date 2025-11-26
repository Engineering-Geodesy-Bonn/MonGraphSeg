function [skel_points_plant, overallEdges_plant] = splitOverlappingLeaves(skel_points_plant, overallEdges_plant, plantStartingNodes, params)
% SPLITOVERLAPPINGLEAVES - Detects and separates overlapping leaf structures in a skeletonized plant.
%
% Syntax:
%   [skel_points_plant, overallEdges_plant] = splitOverlappingLeaves(skel_points_plant, overallEdges_plant, plantStartingNodes, params)
%
% Inputs:
%   skel_points_plant    - Nx5 matrix containing 3D skeleton points and metadata.
%   overallEdges_plant   - Cell array of edges:
%                          {point_indices_sequence, start_node, end_node}.
%   plantStartingNodes   - Indices of root or stem starting points.
%   params              - Struct containing:
%                          .min_cycle_length_overlap - Threshold for detecting overlap cycles.
%                          .junction_merge_distance - Distance threshold for grouping points near junctions.
%
% Outputs:
%   skel_points_plant    - Updated skeleton with labeled overlapping instances.
%   overallEdges_plant   - Updated edge list reflecting the separation of overlapping leaves.
%
% Description:
%   This function detects overlapping leaf structures by identifying long cycles in the graph.
%   It separates overlapping parts by inserting a new skeleton node and updating instances.
%   The approach is inspired by **Miao et al. (2021), "Automatic stem-leaf segmentation of maize shoots using three-dimensional point cloud"**.
%   Their methodology provides a framework for resolving overlapping cycles in plant skeleton graphs.
%
% Example:
%   [skel_points_plant, overallEdges_plant] = splitOverlappingLeaves(skeleton_points, edges, plant_nodes, params);
%
% References:
%   Miao, T., Zhu, C., Xu, T., Yang, T., Li, N., Zhou, Y., & Deng, H. (2021).
%   "Automatic stem-leaf segmentation of maize shoots using three-dimensional point cloud."
%
% See also: allcycles, computeCycleLengths, normalizeVector
% Initialize instance labels
skel_points_plant(:,5) = zeros(size(skel_points_plant,1),1);
instance_id = 1;

% Initialize graph
l = unique(cell2mat(overallEdges_plant(:,2:3)));
graph_B = graph(cell2mat(overallEdges_plant(:,2)), cell2mat(overallEdges_plant(:,3)), ...
    1:length(overallEdges_plant(:,3)));
graph_B.Nodes.Coordinates = skel_points_plant(1:l(end),:);

% Detect all cycles and their lengths
cycles = allcycles(graph_B,"MaxNumCycles",30);
cycle_lengths = computeCycleLengths(graph_B, cycles, overallEdges_plant, skel_points_plant);

while max(cycle_lengths) > params.min_cycle_length_overlap
    [~, idx_longest] = max(cycle_lengths);
    current_cycle = cell2mat(cycles(idx_longest));
    Graph_B_wo_overlap = graph_B;

    % Determine the node closest to the stem/root
    if length(plantStartingNodes) > 1
        closest_nodes = findClosestToAllStartNode(graph_B, plantStartingNodes, current_cycle);
        if length(unique(closest_nodes)) > 1
            unique_nodes = unique(closest_nodes);
            horiz_angles = zeros(length(unique_nodes), 1);
            for i = 1:length(unique_nodes)
                node = unique_nodes(i);
                connected_edges = find( ...
                    cell2mat(overallEdges_plant(:,2)) == node | ...
                    cell2mat(overallEdges_plant(:,3)) == node);
                n1 = skel_points_plant(node, 1:3);
                min_angle = inf;
                for k = connected_edges'
                    endpoints = cell2mat(overallEdges_plant(k, 2:3));
                    neighbor = endpoints(endpoints ~= node);
                    n2 = skel_points_plant(neighbor, 1:3);
                    v = n1 - n2;
                    angle = acosd(v(3)/norm(v));
                    min_angle = min(min_angle, angle);
                end
                horiz_angles(i) = min_angle;
            end
            [~, min_idx] = min(horiz_angles);
            closest_node = unique_nodes(min_idx);
        else
            closest_node = closest_nodes(1);
        end
    else
        closest_node = findClosestTo1StartNode(graph_B, plantStartingNodes, current_cycle);
    end

    % Create new skeleton node to split overlap
    new_node_idx = size(skel_points_plant,1)+1;
    idx_in_cycle = find(current_cycle == closest_node);
    adjacent_edges = getAdjacentEdges(current_cycle, idx_in_cycle);
    n1 = Graph_B_wo_overlap.Nodes.Coordinates(adjacent_edges(1,2),1:3);
    n2 = Graph_B_wo_overlap.Nodes.Coordinates(adjacent_edges(1,1),1:3);
    n3 = Graph_B_wo_overlap.Nodes.Coordinates(adjacent_edges(2,1),1:3);
    [dir_vec, start_pt] = findMoreVerticalAxis(n1, n2, n3);

    max_index = findFurthestNodeOfCentralAxis(skel_points_plant, current_cycle, start_pt, dir_vec);
    junction_point = current_cycle(max_index);

    % Mark skeleton instances
    skel_points_plant_new = skel_points_plant;
    skel_points_plant_new(new_node_idx,:) = [skel_points_plant(junction_point,1:3), new_node_idx, instance_id];
    skel_points_plant_new(junction_point,5) = instance_id;

    % Group surrounding nodes
    dists = pdist2(skel_points_plant(current_cycle,1:3), skel_points_plant(junction_point,1:3));
    nearby_nodes = current_cycle(dists < params.junction_merge_distance);
    reduced_cycle = current_cycle(dists >= params.junction_merge_distance | (current_cycle == junction_point)');
    idx_junction = find(reduced_cycle == junction_point);

    % Update edges for junction correction
    adjacent_edges = getAdjacentEdges(reduced_cycle, idx_junction);
    v1 = normalizeVector(skel_points_plant(adjacent_edges(1,2),1:3) - skel_points_plant(adjacent_edges(1,1),1:3));
    v2 = normalizeVector(skel_points_plant(adjacent_edges(2,1),1:3) - skel_points_plant(adjacent_edges(1,1),1:3));

    overallEdges_plant_new = overallEdges_plant;
    for i = 1:length(nearby_nodes)
        idxs = find(cell2mat(overallEdges_plant_new(:,2)) == nearby_nodes(i));
        for j = idxs'
            overallEdges_plant_new{j,2} = junction_point;
            overallEdges_plant_new{j,1} = [junction_point; overallEdges_plant_new{j,1}(2:end)];
        end
        idxs = find(cell2mat(overallEdges_plant_new(:,3)) == nearby_nodes(i));
        for j = idxs'
            overallEdges_plant_new{j,3} = junction_point;
            overallEdges_plant_new{j,1} = [overallEdges_plant_new{j,1}(1:end-1); junction_point];
        end
    end

    % Remove self-loops
    overallEdges_plant_new(cell2mat(overallEdges_plant_new(:,2)) == cell2mat(overallEdges_plant_new(:,3)),:) = [];

    % Reconstruct graph
    l = unique(cell2mat(overallEdges_plant_new(:,2:3)));
    graph_B = graph(cell2mat(overallEdges_plant_new(:,2)), cell2mat(overallEdges_plant_new(:,3)), ...
        1:length(overallEdges_plant_new(:,3)));
    graph_B.Nodes.Coordinates = skel_points_plant_new(1:l(end),:);

    % Replace junction node with new node where appropriate
    adjacent_edges = getAdjacentEdges(reduced_cycle, idx_junction);
    [overallEdges_plant, overallEdges_plant_new] = replaceJunctionPoint( ...
        graph_B, adjacent_edges(2,:), junction_point, new_node_idx, ...
        overallEdges_plant, overallEdges_plant_new);

    % Further cleanup of adjacent edges
    adj_edges = find(sum([graph_B.Edges.EndNodes(:,1)==junction_point, ...
        graph_B.Edges.EndNodes(:,2)==junction_point],2));
    adj_edge_nodes = graph_B.Edges.EndNodes(adj_edges,:);
    adj_edges = adj_edges(sum(ismember(adj_edge_nodes,reduced_cycle),2)<2);
    eN = graph_B.Edges.EndNodes(adj_edges,:);

    for i = 1:size(eN,1)
        other_node = eN(i,eN(i,:)~=junction_point);
        v3 = normalizeVector(skel_points_plant(other_node,1:3) - skel_points_plant(junction_point,1:3));
        a1 = acosd(dot(v3,v1));
        a2 = acosd(dot(v3,v2));
        if abs(a1 - 180) > abs(a2 - 180)
            edge_idx = graph_B.Edges.Weight(adj_edges(i));
            if overallEdges_plant_new{edge_idx,2} == junction_point
                overallEdges_plant_new{edge_idx,2} = new_node_idx;
                overallEdges_plant_new{edge_idx,1} = [new_node_idx; overallEdges_plant_new{edge_idx,1}(2:end)];
            else
                overallEdges_plant_new{edge_idx,3} = new_node_idx;
                overallEdges_plant_new{edge_idx,1} = [overallEdges_plant_new{edge_idx,1}(1:end-1); new_node_idx];
            end
        end
    end

    % Update data
    overallEdges_plant = overallEdges_plant_new;
    skel_points_plant = skel_points_plant_new;

    % Recalculate cycles
    l = unique(cell2mat(overallEdges_plant(:,2:3)));
    graph_B = graph(cell2mat(overallEdges_plant(:,2)), cell2mat(overallEdges_plant(:,3)), ...
        1:length(overallEdges_plant(:,3)));
    graph_B.Nodes.Coordinates = skel_points_plant(1:l(end),:);
    cycles = allcycles(graph_B);
    cycle_lengths = computeCycleLengths(graph_B, cycles, overallEdges_plant, skel_points_plant);

    instance_id = instance_id + 1;
end
end

function v = normalizeVector(v)
% Normalize a vector (utility)
v = v / norm(v);
end
