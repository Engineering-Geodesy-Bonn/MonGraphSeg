function [neighbors_matrix, points_skel, neighbor_counts] = sortNeighbors(edges_clean, points_skel)
% sortNeighbors - Converts edge list into a neighborhood matrix
%
% Syntax:
%   [neighbors_matrix, skeleton_points, neighbor_counts] = sortNeighbors(edges, skeleton_points)
%
% Inputs:
%   edges           - (Mx2 array) List of edges, each row [pointA, pointB]
%   skeleton_points - (Nx4 array) Skeleton points [X, Y, Z, index] (index will be updated)
%
% Outputs:
%   neighbors_matrix - (NxM array) Matrix containing for each point all its neighbors
%   skeleton_points  - (Nx4 array) Updated skeleton points with correct index in 4th column
%   neighbor_counts  - (Nx1 array) Number of neighbors for each point
%
% Description:
%   This function takes an edge list and constructs a neighborhood matrix where 
%   each row corresponds to a point and the columns list its neighbors.
%   It also ensures each point has a unique index (1:N).

    % Assign a unique index to each skeleton point
    points_skel(:,4) = (1:size(points_skel,1))';
    
    % Preallocate neighborhood matrix
    max_neighbors = 30;  % Assumption: No point has more than 30 neighbors
    neighbors_matrix = zeros(size(points_skel,1), max_neighbors);
    
    % Populate the neighborhood matrix based on edges
    for i = 1:size(edges_clean,1)
        pointA = edges_clean(i,1);
        pointB = edges_clean(i,2);
        
        % Insert pointB as neighbor of pointA
        colA = find(neighbors_matrix(pointA, :) == 0, 1);
        neighbors_matrix(pointA, colA) = pointB;
        
        % Insert pointA as neighbor of pointB
        colB = find(neighbors_matrix(pointB, :) == 0, 1);
        neighbors_matrix(pointB, colB) = pointA;
    end
    
    % Add point indices as the first column
    neighbors_matrix = [points_skel(:,4), neighbors_matrix];
    
    % Remove completely empty columns beyond the first (optional clean-up)
    non_empty_columns = sum(neighbors_matrix) ~= 0;
    neighbors_matrix = neighbors_matrix(:, non_empty_columns);
    
    % Calculate the number of neighbors for each point
    neighbor_counts = sum(neighbors_matrix(:,2:end) > 0, 2);
    
end
