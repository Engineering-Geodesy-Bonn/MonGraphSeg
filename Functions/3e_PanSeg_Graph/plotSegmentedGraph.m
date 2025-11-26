function plotSegmentedGraph(overallEdges_tree, skel_points_tree,name_,options)
% plotSegmentedSkeleton visualizes segmented plant skeleton with color-coded branches.
% Stem edges are shown thicker (LineWidth = 5), leaf segments thinner (LineWidth = 3).
%
% Inputs:
%   overallEdges_tree   - Cell array with edge paths and segmentation labels in column 4
%   skel_points_tree    - Nx3 matrix of 3D point coordinates of the skeleton
if options.plot_enabled
    figure("Name",name_);

    % Extract segment labels
    segment_ids = cell2mat(overallEdges_tree(:,4));
    maxSegmentID = max(segment_ids);
    colors = distinguishable_colors(maxSegmentID);

    % Prepare dummy handles for legend
    hStem = [];
    hLeaf = [];

    % Plot each edge path
    for i = 1:size(overallEdges_tree,1)
        pathIndices = overallEdges_tree{i,1};
        segmentID = segment_ids(i);
        color = colors(segmentID, :);

        % Choose line width and store handle for legend
        if segmentID > 1
            h = plot3(skel_points_tree(pathIndices,1), ...
                skel_points_tree(pathIndices,2), ...
                skel_points_tree(pathIndices,3), ...
                'LineWidth', 3, 'Color', color);
            if isempty(hLeaf)
                hLeaf = h;
            end
        else
            h = plot3(skel_points_tree(pathIndices,1), ...
                skel_points_tree(pathIndices,2), ...
                skel_points_tree(pathIndices,3), ...
                'LineWidth', 5, 'Color', color);
            if isempty(hStem)
                hStem = h;
            end
        end
        hold on;
    end

    % Style plot
    grid on;
    axis equal;
    addAxis_Local();  % Assumes your helper function is available

    % Add legend
    legend([hStem, hLeaf], {'Stem', 'Leaf'}, 'Location', 'Best');
end

end
