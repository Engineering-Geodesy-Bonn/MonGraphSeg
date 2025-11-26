function [edges_xyz, common_endpoints, skeleton_points] = mergeGraphEdges(neighbor_matrix, node_matrix)
% MERGEGRAPHEDGES groups points of a graph into edges between key nodes.
%
% Inputs:
%   neighbor_matrix : Nx(K+1) matrix, [PointID, Neighbor1, Neighbor2, ..., NeighborK]
%   node_matrix     : Nx4 matrix, [X, Y, Z, PointID]
%
% Outputs:
%   edges_xyz        : Cell array, each cell contains the sequence of [X Y Z] points along an edge
%   common_endpoints : Mx2 array, start and end node IDs for each edge
%   skeleton_points  : Updated skeleton points (equal to node_matrix)

% Initialize
skeleton_points = node_matrix;
neighbors = neighbor_matrix(:,2:end);
neighbors = neighbors(:, sum(neighbors) ~= 0); % Remove empty neighbor columns
neighbor_count = sum(logical(neighbors), 2);

% Force root point (highest Z) to be classified correctly
[~, root_idx] = max(skeleton_points(:,3));
if neighbor_count(root_idx) == 2
    neighbor_count(root_idx) = 3;
end

% Classify points
end_points = skeleton_points(neighbor_count == 1, :);
intermediate_points = skeleton_points(neighbor_count == 2, :);
junction_points = skeleton_points(neighbor_count > 2, :);

% Create node structures for junctions and endpoints
nodes = struct('idx', {}, 'x', {}, 'y', {}, 'z', {}, 'is_endpoint', {});
node_counter = 1;

for i = 1:size(junction_points, 1)
    nodes(node_counter) = struct('idx', junction_points(i,4), 'x', junction_points(i,1), 'y', junction_points(i,2), 'z', junction_points(i,3), 'is_endpoint', false);
    node_counter = node_counter + 1;
end
for i = 1:size(end_points, 1)
    nodes(node_counter) = struct('idx', end_points(i,4), 'x', end_points(i,1), 'y', end_points(i,2), 'z', end_points(i,3), 'is_endpoint', true);
    node_counter = node_counter + 1;
end

% Create overview of intermediate points: [X, Y, Z, ID, Neighbor1, Neighbor2, VisitedFlag]
intermediate_overview = [intermediate_points, neighbors(neighbor_count == 2,1:2)];
intermediate_overview(:,7) = 0; % Not visited yet

% Create overview of nodes: [X, Y, Z, ID, Neighbors...]
node_overview = [[ [nodes.x]', [nodes.y]', [nodes.z]', [nodes.idx]' ], [neighbors(neighbor_count > 2,:); neighbors(neighbor_count == 1,:)]];
[~, sort_idx] = sort(node_overview(:,4));
node_overview = node_overview(sort_idx,:);

% Initialize link collection
links = struct('start', {}, 'end', {}, 'path', {});
link_idx = 1;
node_ids = [nodes.idx];

% Build edges by walking through intermediate points
for i = 1:length(nodes)
    start_node_id = nodes(i).idx;
    connected_indices = find(ismember(intermediate_overview(:,5:6), start_node_id));
    for j = 1:length(connected_indices)
        point_idx = connected_indices(j);
        if ~intermediate_overview(point_idx,7)
            intermediate_overview(point_idx,7) = 1;
            neighbors_of_point = intermediate_overview(point_idx,5:6);
            next_point = neighbors_of_point(neighbors_of_point ~= start_node_id);
            previous_id = intermediate_overview(point_idx,4);
            path = previous_id;

            while ~ismember(next_point, node_ids)
                point_idx = find(intermediate_overview(:,4) == next_point);
                intermediate_overview(point_idx,7) = 1;
                neighbors_of_point = intermediate_overview(point_idx,5:6);
                next_point = neighbors_of_point(neighbors_of_point ~= previous_id);
                previous_id = intermediate_overview(point_idx,4);
                path = [path; previous_id];
            end
            path = [path; next_point];

            links(link_idx).start = start_node_id;
            links(link_idx).end = next_point;
            links(link_idx).path = path;
            link_idx = link_idx + 1;
        end
    end
end

% Format the edges
edges_xyz = cell(length(links),1);
common_endpoints = zeros(length(links),2);

for i = 1:length(links)
    full_path = [links(i).start; unique([links(i).path; links(i).end],'stable')];
    edges_xyz{i} = skeleton_points(full_path,:);
    common_endpoints(i,:) = [links(i).start, links(i).end];
end

% Connect remaining node-node edges if necessary
extra_links = struct('start', {}, 'end', {}, 'path', {});
extra_idx = 1;

for i = 1:length(nodes)
    node_neighbors = node_overview(node_overview(:,4) == nodes(i).idx,5:end);
    node_neighbors = node_neighbors(node_neighbors > 0);
    expected_links = length(node_neighbors);

    linked_points = find(ismember(intermediate_overview(:,5:6), nodes(i).idx));
    if length(linked_points) ~= expected_links
        % Some connections between nodes are missing
        neighbor_candidates = node_neighbors(ismember(node_neighbors, node_ids));
        neighbor_candidates = neighbor_candidates(neighbor_candidates > nodes(i).idx); % Avoid duplicate connections
        for k = 1:length(neighbor_candidates)
            extra_links(extra_idx).start = nodes(i).idx;
            extra_links(extra_idx).end = neighbor_candidates(k);
            extra_links(extra_idx).path = [];
            extra_idx = extra_idx + 1;
        end
    end
end

% Format additional edges
extra_edges_xyz = cell(length(extra_links),1);
extra_common_endpoints = zeros(length(extra_links),2);

for i = 1:length(extra_links)
    full_path = [extra_links(i).start; extra_links(i).end];
    extra_edges_xyz{i} = skeleton_points(full_path,:);
    extra_common_endpoints(i,:) = [extra_links(i).start, extra_links(i).end];
end

% Combine all edges
edges_xyz = [edges_xyz; extra_edges_xyz];
common_endpoints = [common_endpoints; extra_common_endpoints];
end
