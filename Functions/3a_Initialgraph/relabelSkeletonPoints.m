function [skeleton_points_final, neighbors_final] = relabelSkeletonPoints(skeleton_points, neighbors_matrix)
% relabelSkeletonPoints - Relabel points with consecutive indices and update neighbor references
%
% Syntax:
%   [skeleton_points_final, neighbors_final] = relabelSkeletonPoints(skeleton_points, neighbors_matrix)
%
% Inputs:
%   skeleton_points  - (Nx4 array) Skeleton points [X, Y, Z, oldIndex]
%   neighbors_matrix - (NxM array) Neighborhood matrix [PointID, Neighbor1, Neighbor2, ...]
%
% Outputs:
%   skeleton_points_final - (Nx4 array) Updated skeleton points with new consecutive indices
%   neighbors_final        - (NxM array) Updated neighborhood matrix with new consecutive neighbor references
%
% Description:
%   This function ensures that skeleton points have consecutive indices (1,2,3,...).
%   It updates the neighborhood matrix so that all neighbor references are adjusted
%   to the new consecutive point indices.
%   Duplicate neighbors are removed and neighbor lists are sorted.

    % Step 1: Create new consecutive indices
    old_indices = skeleton_points(:,4);                           % Get current point indices
    new_indices = (1:size(skeleton_points,1))';                   % Create new consecutive indices

    % Step 2: Update skeleton points
    skeleton_points_final = skeleton_points;
    skeleton_points_final(:,4) = new_indices;

    % Step 3: Initialize final neighbors matrix
    neighbors_final = zeros(size(neighbors_matrix));
    neighbors_final(:,1) = new_indices;                           % Set new consecutive point indices

    % Extract neighbor columns excluding the first (point index column)
    neighbor_data_old = neighbors_matrix(:,2:end);
    neighbor_data_new = neighbors_final(:,2:end);

    % Step 4: Update neighbor references based on new indices
    for i = 1:length(old_indices)
        mask = (neighbor_data_old == old_indices(i));             % Find all occurrences of the old index
        neighbor_data_new(mask) = new_indices(i);                 % Replace with new index
    end

    neighbors_final(:,2:end) = neighbor_data_new;

    % Step 5: Clean up neighbor lists: remove duplicates, remove zeros, and sort
    for i = 1:size(neighbors_final,1)
        current_neighbors = neighbors_final(i,2:end);
        current_neighbors = unique(current_neighbors(current_neighbors > 0)); % Remove zeros and duplicates
        neighbors_final(i,2:end) = [current_neighbors, zeros(1, size(neighbors_final,2) - length(current_neighbors) - 1)];
    end

end
