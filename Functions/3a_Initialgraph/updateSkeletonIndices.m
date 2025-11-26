function [updated_skeleton_points, updated_neighbors] = updateSkeletonIndices(skeleton_points, neighbor_list)
% UPDATESKELETONINDICES ensures consecutive indexing (1:N) of skeleton points 
% and updates the corresponding neighbor list.
%
% Inputs:
%   skeleton_points : Nx4 matrix where column 4 contains the original point IDs
%   neighbor_list   : NxK matrix where column 1 is the point ID and the rest are neighbors
%
% Outputs:
%   updated_skeleton_points : Nx4 matrix with updated point indices in column 4 (1:N)
%   updated_neighbors       : NxK matrix with updated neighbor indices

    % Create new consecutive indices
    original_ids = skeleton_points(:,4);
    new_indices = (1:length(original_ids))';
    id_mapping = [original_ids, new_indices];  % old ID -> new ID

    % Update skeleton points with new indices
    updated_skeleton_points = skeleton_points;
    updated_skeleton_points(:,4) = id_mapping(:,2);

    % Initialize updated neighbor matrix
    updated_neighbors = zeros(size(neighbor_list));
    updated_neighbors(:,1) = id_mapping(:,2);  % new point indices

    original_neighbors = neighbor_list(:,2:end);
    mapped_neighbors = zeros(size(original_neighbors));

    % Map old neighbor IDs to new indices
    for j = 1:size(id_mapping,1)
        mask = original_neighbors == id_mapping(j,1);
        mapped_neighbors(mask) = id_mapping(j,2);
    end
    updated_neighbors(:,2:end) = mapped_neighbors;

    % Ensure neighbors are unique and sorted (optional)
    for i = 1:size(updated_neighbors,1)
        neighbors = updated_neighbors(i,2:end);
        neighbors = unique(neighbors(neighbors > 0));
        updated_neighbors(i,2:end) = [neighbors, zeros(1, size(updated_neighbors,2)-1-length(neighbors))];
    end
end
