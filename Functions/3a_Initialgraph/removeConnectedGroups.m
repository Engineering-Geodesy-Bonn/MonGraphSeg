function [updated_skeleton_points, updated_neighbors] = removeConnectedGroups(skeleton_points, neighbor_matrix, neighbor_counts)
%REMOVECONNECTEDGROUPS Detects and merges connected junction point groups in the skeleton.
%
% INPUTS:
%   skeleton_points  : [N x 4] matrix with skeleton nodes (X, Y, Z, ID)
%   neighbor_matrix  : [N x K] matrix where each row starts with a node ID followed by its neighbors
%   neighbor_counts  : [N x 1] vector indicating the number of neighbors per node
%
% OUTPUTS:
%   updated_skeleton_points : Re-sampled skeleton points after merging junctions
%   updated_neighbors       : Updated neighbor matrix with merged junction nodes

% Step 1: Identify junction points (nodes with more than two neighbors)
junction_nodes = skeleton_points(neighbor_counts > 2, :);
junction_neighbor_matrix = neighbor_matrix(ismember(neighbor_matrix(:,1), find(neighbor_counts > 2)), :);

% Remove non-junction neighbors from rows
only_junction_neighbors = junction_neighbor_matrix(:,2:end);
only_junction_neighbors(~ismember(only_junction_neighbors, find(neighbor_counts > 2))) = 0;
junction_neighbor_matrix(:,2:end) = only_junction_neighbors;

% Step 2: Group connected junction nodes
connected_groups = groupConnectedPoints(junction_neighbor_matrix);

if isempty(connected_groups)
    % No connected junctions → return original input
    updated_skeleton_points = skeleton_points;
    updated_neighbors = neighbor_matrix;
    return;
end

% Step 3: Initialization
max_existing_id = max(skeleton_points(:,4));
next_id = max_existing_id + 1;

updated_points = skeleton_points;
neighbor_id_matrix = neighbor_matrix(:,2:end);
updated_neighbors = neighbor_matrix;
deletion_mask = zeros(size(neighbor_matrix,1),1);

new_neighbor_rows = zeros(size(junction_nodes,1), 800);  % Preallocate
new_nodes = zeros(size(junction_nodes,1), 4);  % [X, Y, Z, ID]

point_flags = zeros(length(skeleton_points),3);  % [changed?, groupID, originalID]
point_flags(:,3) = skeleton_points(:,4);
id_map = [skeleton_points(:,4), zeros(length(skeleton_points),1)];  % [oldID, newID]

counter = 1;
for g = 1:length(connected_groups)
    group = skeleton_points(connected_groups{g}, :);
    point_flags(group(:,4),1) = 1;
    point_flags(group(:,4),2) = g;

    % Subdivide by z-value bands (0.5 mm bins)
    z = group(:,3);
    z_shifted = z - min(z);
    z_bins = floor(z_shifted / 0.5) + 1;
    unique_bins = unique(z_bins);

    for b = 1:length(unique_bins)
        sub_group = group(z_bins == unique_bins(b), :);
        old_ids = sub_group(:,4);

        % Create new merged node (mean position)
        new_coord = mean(sub_group(:,1:3), 1);
        new_nodes(counter,:) = [new_coord, next_id];

        % Replace all neighbor references to old IDs with the new one
        mask = ismember(neighbor_id_matrix, old_ids);
        neighbor_id_matrix(mask) = next_id;

        % Record ID mapping
        id_map(old_ids,2) = next_id;

        % Collect neighbors of original nodes
        neighbor_set = updated_neighbors(ismember(updated_neighbors(:,1), old_ids), 2:end);
        neighbor_set = neighbor_set(:);

        % Connect across z-layers
        if b > 1
            neighbor_set = [neighbor_set; next_id - 1];
        end
        if b < length(unique_bins)
            neighbor_set = [neighbor_set; next_id + 1];
        end

        % Clean and write to new neighbor matrix
        neighbor_set = unique(neighbor_set(neighbor_set > 0));
        if length(neighbor_set) > 800
            warning("Too many neighbors (>800) in new junction group.");
        end
        new_neighbor_rows(counter, 1:length(neighbor_set)+1) = [next_id, neighbor_set'];

        deletion_mask(old_ids) = 1;
        counter = counter + 1;
        next_id = next_id + 1;
    end
end

% Step 4: Finalize points and neighbors
new_nodes = new_nodes(1:counter-1,:);
updated_points(deletion_mask==1,:) = [];
updated_points = [updated_points; new_nodes];

% Clean up neighbor matrix
updated_neighbors(:,2:end) = neighbor_id_matrix;
updated_neighbors(deletion_mask==1,:) = [];
updated_neighbors(:,end+1:800) = 0;
updated_neighbors = [updated_neighbors; cleanNewNeighborRows(new_neighbor_rows, deletion_mask)];

% Remove empty columns
col_sums = sum(updated_neighbors, 1);
last_valid_col = find(col_sums == 0, 1) - 1;
updated_neighbors = updated_neighbors(:, 1:last_valid_col);

% Step 5: Connect between different junction groups if needed
updated_neighbors = connectDifferentGroups(point_flags, neighbor_matrix, updated_neighbors, id_map);

% Step 6: Handle cross-connections between junction groups (post-merge)
point_flags = point_flags(logical(point_flags(:,1)),:);
unique_groups = unique(point_flags(:,2));

for i = 1:length(unique_groups)
    group1_ids = point_flags(point_flags(:,2)==unique_groups(i),3);
    for j = i+1:length(unique_groups)
        group2_ids = point_flags(point_flags(:,2)==unique_groups(j),3);
        for k = 1:length(group2_ids)
            common = group1_ids(any(ismember(neighbor_matrix(group1_ids,2:end), group2_ids(k)),2));
            if ~isempty(common)
                nid1 = id_map(common,2);
                nid2 = id_map(group2_ids(k),2);

                % Forward connection
                neigh1 = updated_neighbors(updated_neighbors(:,1)==nid1,2:end);
                neigh1 = neigh1(neigh1 > 0);
                if ~ismember(nid2, neigh1)
                    updated_neighbors(updated_neighbors(:,1)==nid1, length(neigh1)+2) = nid2;
                end

                % Backward connection
                neigh2 = updated_neighbors(updated_neighbors(:,1)==nid2,2:end);
                neigh2 = neigh2(neigh2 > 0);
                if ~ismember(nid1, neigh2)
                    updated_neighbors(updated_neighbors(:,1)==nid2, length(neigh2)+2) = nid1;
                end
            end
        end
    end
end

% Step 7: Reindex
[updated_skeleton_points, updated_neighbors] = updateSkeletonIndices(updated_points, updated_neighbors);

end
