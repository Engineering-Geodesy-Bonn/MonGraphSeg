function overallEdges_tree_pruned = detectAndRemoveSpuriousStemTip(overallEdges_tree_pruned, ptCloud_all, skel_points_tree, plantStartingNodes_tree, ground_existing, params)
% DETECTANDREMOVESPURIUSSTEMTIP Detects and removes spurious stem tip instances
%
% This function checks if the stem tip is a spurious detection by splitting
% the stem into two parts, analyzing point density, and merging the tip back
% into the main stem if it's determined to be spurious.
%
% Inputs:
%   overallEdges_tree_pruned  - Cell array of pruned graph edges
%   ptCloud_all               - Nx3 or NxM array of point cloud data
%   skel_points_tree          - Skeleton points of the tree structure
%   plantStartingNodes_tree   - Starting nodes of the plant structure
%   ground_existing           - Boolean flag indicating if ground exists
%   params                    - Structure containing algorithm parameters
%                               Required field: max_points_segmentation
%
% Output:
%   overallEdges_tree_pruned  - Updated cell array with spurious tip removed (if detected)
%
% Algorithm:
%   1. Split the stem edge at the last branching point
%   2. Create a temporary stem tip instance
%   3. Reassign point cloud points to instances
%   4. Check if stem tip has sufficient point support
%   5. If spurious, merge tip back into main stem
%
% Author: Annika Tobies, 2025

    % Split stem into two parts to check if tip is spurious
    overallEdges_tree_pruned_StemEnd = overallEdges_tree_pruned;
    
    % Find the last branching point on the stem
    index_ = find(overallEdges_tree_pruned_StemEnd{1,1}==overallEdges_tree_pruned_StemEnd{end,2});
    
    % Create new stem tip instance from branching point to end
    overallEdges_tree_pruned_StemEnd{end+1,1} = overallEdges_tree_pruned_StemEnd{1,1}(index_:end);
    overallEdges_tree_pruned_StemEnd{1,1} = overallEdges_tree_pruned_StemEnd{1,1}(1:index_);
    
    % Reassign points for stem tip detection
    edges_panoptic = cellfun(@(idx) skel_points_tree(idx, 1:3), overallEdges_tree_pruned_StemEnd(:,1), 'UniformOutput', false);
    pointLabels = SegmentationPointCloud(ptCloud_all, edges_panoptic, params.max_points_segmentation, ground_existing, skel_points_tree, plantStartingNodes_tree(1));
    
    % Check if stem tip is spurious based on point density
    [topSpurious, ~,~,~] = detectSpuriousInstances_stemTip(ptCloud_all, pointLabels(:,1), overallEdges_tree_pruned_StemEnd, skel_points_tree, params, ground_existing);
    
    % If spurious, merge tip back into stem
    if topSpurious
        % Remove the temporary tip instance
        overallEdges_tree_pruned_StemEnd(end,:) = []; 
        % Merge tip points back into stem
        overallEdges_tree_pruned_StemEnd{1,1} = [overallEdges_tree_pruned_StemEnd{1,1}; overallEdges_tree_pruned_StemEnd{end,1}];
        % Update stem endpoint
        overallEdges_tree_pruned_StemEnd{1,3} = overallEdges_tree_pruned_StemEnd{end,3};
        % Remove the merged instance
        overallEdges_tree_pruned_StemEnd(end,:) = [];
        % Update output
        overallEdges_tree_pruned = overallEdges_tree_pruned_StemEnd;
    end
    
end
