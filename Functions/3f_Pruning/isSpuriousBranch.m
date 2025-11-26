function is_spurious = isSpuriousBranch(points_branch, occ_matrix_others, node_indices, skel_points, voxel_step, edges_x, edges_y, edges_z)
% Compares occupancy clustering before and after adding the branch
    is_spurious = true;

    sampled_nodes = node_indices(1:voxel_step:end);
    distance_ = pdist2(points_branch(:,1:3), skel_points(sampled_nodes, 1:3));
    [~, idx_edge_node] = min(distance_');
    unique_edges = unique(idx_edge_node);

    for l = 1:length(unique_edges)-1
        idx_range = ismember(idx_edge_node, unique_edges(l):unique_edges(end));
        partial_points = points_branch(idx_range, :);

        occ_matrix_branch = createOccupancyMatrix(partial_points, edges_x, edges_y, edges_z);
        occ_combined = occ_matrix_branch + occ_matrix_others;

        n_clusters_before = bwconncomp(occ_matrix_others).NumObjects;
        n_clusters_after  = bwconncomp(occ_combined).NumObjects;

        if n_clusters_after > n_clusters_before
            is_spurious = false;
            return;
        end
    end
end
