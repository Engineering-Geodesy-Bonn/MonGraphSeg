function updated_neighbors = connectDifferentGroups_TaSp(changed_points, neighbors_matrix, updated_neighbors, id_translation)
% CONNECTDIFFERENTGROUPS connects points (junctions and starting points) from different groups if they are neighbors.
%
% This function ensures that if two points from different structural groups 
% (e.g. stem segments) are adjacent in the original graph, their corresponding 
% updated nodes will also be connected in the updated_neighbors matrix.
%
% Inputs:
%   changed_points    : Nx3 matrix, each row is [is_changed_flag, group_id, old_index]
%   neighbors_matrix  : NxM matrix, original neighborhood (row i contains neighbors of node i)
%   updated_neighbors : PxQ matrix, updated neighborhood (first column is new ID)
%   id_translation    : Nx2 matrix, [old_index, new_index]
%
% Output:
%   updated_neighbors : PxQ matrix with added connections between separate groups

    % Filter only changed points
    changed_points = changed_points(logical(changed_points(:,1)), :);
    
    % Identify unique group IDs
    unique_groups = unique(changed_points(:,2));

    % Loop through all pairs of distinct groups
    for i = 1:length(unique_groups)
        group1_indices = changed_points(changed_points(:,2) == unique_groups(i), 3);

        for j = i+1:length(unique_groups)
            group2_indices = changed_points(changed_points(:,2) == unique_groups(j), 3);

            for k = 1:length(group2_indices)
                idx2 = group2_indices(k);

                % Check for neighboring points from group1 to current point in group2
                neighbors_from_group1 = group1_indices( ...
                    any(neighbors_matrix(group1_indices,2:end) == idx2, 2));

                if ~isempty(neighbors_from_group1)
                    for n = 1:length(neighbors_from_group1)
                        idx1 = neighbors_from_group1(n);
                        new_idx1 = id_translation(idx1, 2);
                        new_idx2 = id_translation(idx2, 2);

                        % Add connection in updated_neighbors (from new_idx1 to new_idx2)
                        row1 = updated_neighbors(updated_neighbors(:,1) == new_idx1, :);
                        neighbors1 = row1(2:end);
                        neighbors1 = neighbors1(neighbors1 > 0);
                        if ~ismember(new_idx2, neighbors1)
                            updated_neighbors(updated_neighbors(:,1) == new_idx1, length(neighbors1)+2) = new_idx2;
                        end

                        % Add connection in reverse direction (from new_idx2 to new_idx1)
                        row2 = updated_neighbors(updated_neighbors(:,1) == new_idx2, :);
                        neighbors2 = row2(2:end);
                        neighbors2 = neighbors2(neighbors2 > 0);
                        if ~ismember(new_idx1, neighbors2)
                            updated_neighbors(updated_neighbors(:,1) == new_idx2, length(neighbors2)+2) = new_idx1;
                        end
                    end
                end
            end
        end
    end
end
