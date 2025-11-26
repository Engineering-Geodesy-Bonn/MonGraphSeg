function [spurious_instances,edges_x, edges_y, edges_z] = detectSpuriousInstances_stem( ...
    ptCloud_all, pointLabels, overallEdges_tree_concluded, ...
    skel_points_tree, params, ground_existing)
%DETECTSPURIOUSINSTANCES Identifies spurious branches based on voxel occupancy clustering
%
% INPUTS:
%   ptCloud_all               - Nx3 matrix of all point coordinates
%   pointLabels               - Nx1 vector: point-to-cluster assignments
%   overallEdges_tree_concluded - Cell array with skeleton paths (per plant)
%   skel_points_tree          - Skeleton node positions
%   params               - Struct with field .VoxelSize_pruning
%   ground_existing           - Boolean indicating if ground is part of labels
%
% OUTPUT:
%   spurious_instances        - Logical vector, 1 = spurious instance


% Remove ground label if present
unique_clusters = unique(pointLabels);
if ground_existing
    unique_clusters(end) = [];
end

% Voxel grid boundaries
[edges_x, edges_y, edges_z] = computeVoxelEdges(ptCloud_all, params.voxel_size_pruning_mm);

% Preallocate result
spurious_instances = zeros(size(overallEdges_tree_concluded,1), 1);

% Loop over all instances (skip index 1 = stem)
for i = 2:size(overallEdges_tree_concluded,1)
    % All points not in current instance
    overlap_existing = skel_points_tree(overallEdges_tree_concluded{i,1},5);
    overlap_existing_i = unique(overlap_existing);
    if length(overlap_existing)>1
        notConsiderd_Clusters = [];
        % Optimized: vectorized overlap detection
        for k = 2:length(overlap_existing_i)
            for j = 1:size(overallEdges_tree_concluded,1)
                if j~=i
                    overlap_existing_j = unique(skel_points_tree(overallEdges_tree_concluded{j,1},5));
                    if ismember(overlap_existing_i(k),overlap_existing_j)
                        notConsiderd_Clusters = [notConsiderd_Clusters;j]; %#ok<AGROW>
                    end
                end
            end
        end
        % Optimized: logical indexing instead of ismember twice
        excluded_labels = [i;notConsiderd_Clusters];
        mask = ~ismember(pointLabels, excluded_labels);
        points_withOut = ptCloud_all(mask, 1:3);
    else
        % Optimized: direct logical indexing
        points_withOut = ptCloud_all(pointLabels ~= i, 1:3);
    end
    occ_matrix_without = createOccupancyMatrix(points_withOut, edges_x, edges_y, edges_z);

        % Current cluster points
    points_cluster = ptCloud_all(pointLabels == i, 1:3);
    
      
    nodes_cluster = overallEdges_tree_concluded{i,1};
    sampled_nodes = nodes_cluster(1:params.voxel_size_pruning_mm:end);
    distance_ = pdist2(points_cluster(:,1:3), skel_points_tree(sampled_nodes, 1:3));
    [~, idx_edge_node] = min(distance_', [], 1); % faster transpose
    unique_edges = unique(idx_edge_node);

    % Check segment-wise if adding it increases clusters → non-spurious
    spurious_branch = true;
    for l = 1:length(unique_edges)
        range = ismember(idx_edge_node, unique_edges(l):unique_edges(end));
        points_cluster_l = points_cluster(range, :);
              
        occ_matrix_i = createOccupancyMatrix(points_cluster_l, edges_x, edges_y, edges_z);
        occ_matrix_together = occ_matrix_i + occ_matrix_without;

  

        cluster_before = bwconncomp(occ_matrix_without).NumObjects;
        cluster_after  = bwconncomp(occ_matrix_together).NumObjects;

        if cluster_after > cluster_before
            spurious_branch = false;
            break;
        end
    end

    % Mark as spurious if all subparts are connected to the rest
    if spurious_branch
        spurious_instances(i) = 1;
    end
end
end
