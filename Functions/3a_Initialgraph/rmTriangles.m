function [edges_clean] = rmTriangles(edges)
% rmTriangles - Remove triangles (hypotenuses) from a graph structure, to
% remove Triangles in graph structure
%
% Syntax:
%   edges_clean = rmTriangles(edges)
%
% Inputs:
%   edges           - (Mx3 array) List of edges, each row [node1, node2, weight]
%   skeleton_points - (Nx3 array) Coordinates of the skeleton points (unused here, but useful for debugging/plotting)
%
% Output:
%   edges_clean     - (Kx3 array) Edge list after removing triangles (hypotenuses are deleted)
%
% Description:
%   This function iteratively detects triangles in a given edge list and removes 
%   the edge with the largest weight (the hypotenuse). 
%   The purpose is to ensure a linear graph structure without triangle shortcuts.

    % Initialize the cleaned edges list
    edges_clean = edges;

    % Loop over each node (first node of the edge)
    for i = 1:length(edges)
        node1 = edges(i,1); % First node
        
        % Find all edges starting from this node
        connected_edges = edges_clean(edges_clean(:,1) == node1, :);
        delete_indices = [];  % To store edges to be deleted
        
        % Compare each pair of connected edges
        for j = 1:size(connected_edges,1) - 1
            node2 = connected_edges(j,2); % Second node
            for k = j+1:size(connected_edges,1)
                node3 = connected_edges(k,2); % Third node

                % Check if an edge exists between node2 and node3
                idx0 = find(edges_clean(:,1) == node1 & edges_clean(:,2) == node2);
                idx1 = find(edges_clean(:,1) == node1 & edges_clean(:,2) == node3);
                idx2 = find(edges_clean(:,1) == node2 & edges_clean(:,2) == node3);

                if ~isempty(idx1) && ~isempty(idx2) % Triangle detected
                    % Triangle detected between node1, node2, node3
                    triangle_indices = [idx0; idx1; idx2];
                    
                    % Identify the longest edge (hypotenuse) by maximum weight
                    [~, idx_max] = max(edges_clean(triangle_indices,3));
                    
                    % Mark the hypotenuse edge for deletion
                    delete_indices = [delete_indices; triangle_indices(idx_max)];
                end
            end
        end
        
        % Delete the identified edges from the clean edge list
        edges_clean(delete_indices,:) = [];
    end

end
