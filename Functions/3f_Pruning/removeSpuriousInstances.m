function spurious_instances = removeSpuriousInstances(...
    ptCloud_all, pointLabels, overallEdges_tree_pruned, ...
    skel_points_tree, edges_x, edges_y, edges_z, ...
    A_parameter, ground_existing, showDebug)
% Checks if whole instance is connected to ground
    if ~ground_existing
        spurious_instances = zeros(size(overallEdges_tree_pruned, 1), 1);
        return;
    end

    % Optimized: Extract points connected to the ground (assumed: label with highest value)
    max_label = max(pointLabels);
    points_withOut = ptCloud_all(pointLabels == max_label, 1:3);
    occ_matrix_without = createOccupancyMatrix(points_withOut, edges_x, edges_y, edges_z);
    
    spurious_instances = zeros(size(overallEdges_tree_pruned, 1), 1);

    for i = 2:size(overallEdges_tree_pruned, 1)  
        points_cluster = ptCloud_all(pointLabels == i, 1:3);

        if showDebug
            figure;
            scatter3(points_withOut(:,1), points_withOut(:,2), points_withOut(:,3), '.', 'MarkerEdgeAlpha', 0.1); hold on;
            scatter3(points_cluster(:,1), points_cluster(:,2), points_cluster(:,3), '.');
            title(['Cluster ', num2str(i)]);
        end

        % Get skeletal nodes of the current cluster
        nodes_cluster = overallEdges_tree_pruned{i,1};
        sampled_nodes = nodes_cluster(1:A_parameter.voxel_size_pruning_mm:end);

        % Find skeleton region closest to cluster points
        distance_ = pdist2(points_cluster(:,1:3), skel_points_tree(sampled_nodes, 1:3));
        [~, idx_edge_node] = min(distance_', [], 1);  % faster with transpose
        unique_edges = unique(idx_edge_node);

        spurious_branch = true;

        % Check, step by step, if this branch is connected to the rest
        for l = 1:length(unique_edges)
            range = ismember(idx_edge_node, unique_edges(1):unique_edges(l));
            points_cluster_l = points_cluster(range, :);

            if showDebug
                scatter3(points_cluster_l(:,1), points_cluster_l(:,2), points_cluster_l(:,3), 'filled');
                drawnow;
            end

            % Create occupancy matrix for partial branch
            occ_matrix_i = createOccupancyMatrix(points_cluster_l, edges_x, edges_y, edges_z);
            occ_matrix_together = occ_matrix_i + occ_matrix_without;

            % Compare number of connected components before and after
            cluster_before = bwconncomp(occ_matrix_without).NumObjects;
            cluster_after  = bwconncomp(occ_matrix_together).NumObjects;

            if cluster_after > cluster_before
                % Connecting the current segment increases the number of components → not spurious
                spurious_branch = false;
                break;
            end
        end

        % Mark as spurious if all parts are connected to the existing structure
        if spurious_branch
            spurious_instances(i) = 1;
        end
    end

    % Remove spurious branches
    overallEdges_tree_pruned = overallEdges_tree_pruned(~spurious_instances,:);
end
