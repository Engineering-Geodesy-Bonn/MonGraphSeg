function [overallEdges_tree_panSeg_tip,skel_points_tree_tip] = improvement_tipNode(...
    overallEdges_tree_pruned, skel_points_tree, ...
    ptCloud_all,pointLabels,idx_skel_closest)

% IMPROVEMENT_TIPNODE - Extends the tip of each pruned plant skeleton by
% extrapolating its direction and assigning a new endpoint.
%
% Inputs:
%   overallEdges_tree_pruned   - Full set of pruned plant skeleton trees
%   overallEdges_tree_panSeg   - Segmented trees to be tip-extended
%   skel_points_tree           - Global skeleton node coordinates
%   ptCloud_all                - Full point cloud (Nx3)
%   plantStartingNodes_tree    - Starting nodes for each tree
%   ground_existing            - Boolean flag indicating if ground is present
%
% Output:
%   overallEdges_tree_panSeg_tip - Updated tree segments with extended tip nodes

% Initialize outputs
overallEdges_tree_panSeg_tip = overallEdges_tree_pruned;
skel_points_tree_tip = skel_points_tree;

% Iterate over all segmented branches
for i = 1:size(overallEdges_tree_panSeg_tip, 1)
    % Length of current branch (in number of nodes)
    branch_nodes = overallEdges_tree_panSeg_tip{i,1};
    branch_length = size(branch_nodes, 1) - 1;

    % Get points assigned to this branch
    idx_points_branch = find(pointLabels == i);
    idx_skel = idx_skel_closest(idx_points_branch);
    points_branch_tip = ptCloud_all(idx_points_branch(idx_skel == branch_length), 1:3);
    if ~isempty(points_branch_tip)

        % Get last two skeleton points to compute direction vector
        node_tip = skel_points_tree(branch_nodes(end), 1:3);


        node_prev = skel_points_tree(branch_nodes(end-1), 1:3);
        direction_vector = node_tip - node_prev;

        % Extrapolation parameters for tip extension
        line_sample_step = 0.001;     % Step size for line sampling
        line_max_length = 10;         % Maximum extrapolation distance [mm]
        
        % Extrapolate a line in the tip direction
        t = 0:line_sample_step:line_max_length;
        line_points = node_prev + direction_vector .* [t', t', t'];

        
        % Find closest extrapolated point for each candidate tip point
        [idx_closest, ~] = knnsearch(line_points,points_branch_tip,"K",1);

        
        % Identify the extrapolated point furthest along the direction
        max_idx = max(idx_closest);
        extrapolated_target = line_points(max_idx, :);

        % Find candidate points assigned to this extrapolated location
        candidate_points = points_branch_tip(idx_closest == max_idx, :);

        % Choose the closest candidate point to the extrapolated target
        [~, idx_nearest] = min(pdist2(extrapolated_target, candidate_points));
        new_tip_point = candidate_points(idx_nearest, :);




        % Add new skeleton point
        new_node_index = size(skel_points_tree_tip, 1) + 1;
        skel_points_tree_tip = [skel_points_tree_tip; new_tip_point, new_node_index',0];

        % Update tree structure with new node
        overallEdges_tree_panSeg_tip{i,1} = [branch_nodes; new_node_index'];
        overallEdges_tree_panSeg_tip{i,3} = new_node_index(end);
    end
end
end
