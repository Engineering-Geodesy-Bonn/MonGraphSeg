function edges_connected = connectGraphComponents(points_skel, edges_clean)
% CONNECTGRAPHCOMPONENTS - Ensures that all disconnected parts of a graph are connected.
%
% Syntax:
%   edges_connected = connectGraphComponents(points_skel, edges_clean)
%
% Inputs:
%   points_skel  - (Nx3 array) Node coordinates in the skeleton graph.
%   edges_clean  - (Mx2 array) Initial set of edges (node indices) before connecting components.
%
% Outputs:
%   edges_connected - (Kx2 array) Updated edge list ensuring a fully connected graph.
%
% Description:
%   This function takes a set of graph edges and ensures that all disconnected components 
%   are merged into a single connected graph using nearest-neighbor connections.
%
% Workflow:
%   1. Construct a graph with all nodes and initial edges.
%   2. Identify connected components using conncomp.
%   3. Iteratively connect components:
%      a. Find a small disconnected component.
%      b. Determine the closest node from another component using Euclidean distance.
%      c. Add an edge to merge the two components.
%      d. Repeat until only one connected component remains.
%
% Example:
%   edges_connected = connectGraphComponents(skeletonPoints, edges_clean);
%
% See also: graph, conncomp, pdist2, addedge

    % Step 1: Initialize graph with nodes and edges
    G = graph;
    G = addnode(G, size(points_skel,1));  
    G.Nodes.Coor = points_skel(:,1:3);  % Store node coordinates
    G = addedge(G, edges_clean(:,1), edges_clean(:,2));  % Add initial edges

    % Step 2: Identify connected components
    bins = conncomp(G);

    % Step 3: Iteratively connect graph components until fully connected
    while numel(unique(bins)) > 1
        unique_bins = unique(bins);
        current_bin = unique_bins(2);  % Select a small disconnected component
        remaining_bins = unique_bins(unique_bins ~= current_bin);  % Exclude it

        % Extract coordinates and indices of the current component
        coords_current = G.Nodes(bins == current_bin, :).Coor;
        indices_current = find(bins == current_bin);

        % Initialize variables for distance calculations
        min_distances = inf(size(remaining_bins));
        connection_indices = zeros(length(remaining_bins),2);

        % Find the closest node in another component
        for i = 1:numel(remaining_bins)
            coords_other = G.Nodes(bins == remaining_bins(i), :).Coor;
            distances = pdist2(coords_current, coords_other);

            % Identify the closest pair of nodes
            [minDist, linearIndex] = min(distances(:));
            [rowIdx, colIdx] = ind2sub(size(distances), linearIndex);
            min_distances(i) = minDist;
            connection_indices(i,:) = [rowIdx, colIdx];
        end

        % Determine the nearest component to connect
        [~, min_idx] = min(min_distances);
        target_indices = find(bins == remaining_bins(min_idx));

        % Step 4: Add edge connecting the nearest nodes from two components
        G = addedge(G, ...
            indices_current(connection_indices(min_idx,1)), ...
            target_indices(connection_indices(min_idx,2)));

        % Update connected components
        bins = conncomp(G);
    end

    % Return the fully connected edge list
    edges_connected = G.Edges.EndNodes;

end
