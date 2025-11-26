function overallEdges = traceGraphEdges(updated_neighbors, updated_skeleton_points)
% TRACEGRAPHEDGES traces all edges in a graph from nodes through intermediate points.
%
% Inputs:
%   updated_neighbors      : NxM neighbor matrix (first column = ID, following columns = neighbors)
%   updated_skeleton_points: Nx4 matrix of points [X, Y, Z, ID]
%
% Outputs:
%   overallEdges : Cell array where each row contains:
%                  - column 1: list of point IDs forming an edge
%                  - column 2: start node ID
%                  - column 3: end node ID

% Step 1: Clean and classify points
% Remove empty neighbor columns
updated_neighbors = updated_neighbors(:, sum(updated_neighbors) ~= 0);

% Compute number of neighbors for each point (excluding itself)
sum_nh = sum(logical(updated_neighbors), 2) - 1;

% Ensure that the highest Z-point (usually the root) is treated correctly -
% important for ground/plant separation
[~, root_idx] = max(updated_skeleton_points(:,3));
if sum_nh(root_idx) == 2
    sum_nh(root_idx) = 3;
end

% Classify nodes
Node_Terminal = updated_skeleton_points(sum_nh == 1, :); % Terminal nodes (one neighbor)
Node_Junction = updated_skeleton_points(sum_nh > 2, :);  % Junction nodes (more than two neighbors)

% Step 2: Create a structured overview of important nodes and edges
node_begin_OE = [
    Node_Junction(:, [4,1,2,3]), updated_neighbors(sum_nh > 2, :); 
    Node_Terminal(:, [4,1,2,3]), updated_neighbors(sum_nh == 1, :)
];

% Prepare overview for intermediate nodes
overview_Node_Between = [
    updated_neighbors(sum_nh == 2, 1:2);
    updated_neighbors(sum_nh == 2, [1,3])
];
overview_Node_Between = unique(sort(overview_Node_Between, 2), "rows");
overview_Node_Between = [overview_Node_Between, false(size(overview_Node_Between, 1), 1)]; % Add 'processed' flag

% Step 3: Trace the graph edges
edge_idx = 1;
overallEdges = cell(0,3);

for i = 1:size(node_begin_OE,1) % Loop over all terminal and junction nodes
    % Find connected intermediate nodes
    connected = find(sum(ismember(overview_Node_Between(:,1:2), node_begin_OE(i,1)), 2));
    for j = 1:length(connected)
        node_between_idx = connected(j);
        if ~overview_Node_Between(node_between_idx, 3) % If not already processed
            neighbors = overview_Node_Between(node_between_idx, 1:2);
            next_node = neighbors(neighbors ~= node_begin_OE(i,1));
            end_reached = ismember(next_node, node_begin_OE(:,1));
            path_ids = [node_begin_OE(i,1); next_node];
            overview_Node_Between(node_between_idx, 3) = true; % Mark as processed

            % Follow the path until another terminal or junction node is found
            while ~end_reached
                current_node = next_node;
                current_idx = find(sum(ismember(overview_Node_Between(:,1:2), current_node), 2));
                neighbors = overview_Node_Between(current_idx, 1:2);
                % Ignore already visited nodes
                neighbors = neighbors(~overview_Node_Between(current_idx,3), :);
                current_idx = current_idx(~overview_Node_Between(current_idx,3));
                next_node = neighbors(neighbors ~= current_node);
                end_reached = ismember(next_node, node_begin_OE(:,1));
                path_ids = [path_ids; next_node];
                overview_Node_Between(current_idx,3) = true; % Mark as processed
            end

            % Save the complete edge
            overallEdges{edge_idx,1} = path_ids; % Full path (node IDs)
            overallEdges{edge_idx,2} = path_ids(1); % Start node
            overallEdges{edge_idx,3} = path_ids(end); % End node
            edge_idx = edge_idx + 1;
        end
    end
end

% Add Junction/Endpoint Connection
temp = updated_neighbors(ismember(updated_neighbors(:,1), Node_Terminal(:,4)),:);
addedEdges = ismember(temp(:,2:end),Node_Junction(:,4));
temp2_ = temp(:,2:end);
find_index = find(addedEdges);
together_ =[ temp(find_index,1),temp2_(addedEdges)];
for i = 1:length(find_index)
    overallEdges{end+1,1} = (fliplr(together_(i,:)))';
    overallEdges{end,2} = together_(i,2);
     overallEdges{end,3} =together_(i,1);    
end

 overallEdges = connectJunctionPoints(updated_neighbors, sum_nh, overallEdges);
end
