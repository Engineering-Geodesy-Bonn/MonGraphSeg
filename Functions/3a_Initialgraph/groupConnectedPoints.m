function group_cells = groupConnectedPoints(neighbor_table)
% groupConnectedPoints - Group points into connected components based on their neighbors
%
% Syntax:
%   group_cells = groupConnectedPoints(neighbor_table)
%
% Input:
%   neighbor_table - (NxM array)
%       - First column: point indices (arbitrary values, not necessarily consecutive)
%       - Columns 2:end: neighbor indices (zero-padded, use 0 if no neighbor)
%
% Output:
%   group_cells - (1xG cell array)
%       - Each cell contains the list of compact indices (rows of neighbor_table) belonging to one group
%
% Description:
%   This function groups points into connected components based on their neighbor relationships.
%   It constructs an undirected graph from the neighbor list and identifies connected components
%   using MATLAB's graph theory tools. Only groups containing at least two points are kept.
%
% Example:
%   group_cells = groupConnectedPoints(neighbor_table);
%
% Notes:
%   - Points that are not connected to any other are ignored.
%   - Neighbor table must not contain negative values.



    % Initialize edge list
    edges = [];
    for i = 1:size(neighbor_table,1)
        current_point = neighbor_table(i,1);
        neighbors = neighbor_table(i,2:end);
        neighbors = neighbors(neighbors > 0); % Remove zeros
        
        % Add edges: current_point connected to each neighbor
        edges = [edges; repmat(current_point, numel(neighbors), 1), neighbors(:)];
    end

    % Handle case when no edges exist
    if isempty(edges)
        group_cells = {}; % No groups
        return;
    end

    % Build undirected graph from edges
    G = graph(edges(:,1), edges(:,2));
    
    % Find connected components
    component_labels = conncomp(G); % Gives group label for each unique point ID in the graph
    
    % Determine number of groups
    num_groups = max(component_labels);

    % Initialize output cell array
    group_cells = cell(1, num_groups);

    % Fill the cell array with points belonging to each group
    for g = 1:num_groups
        group_cells{g} = find(component_labels == g);
    end

    % Remove groups that contain only a single point
    group_sizes = cellfun(@numel, group_cells);
    group_cells = group_cells(group_sizes > 1);

end
