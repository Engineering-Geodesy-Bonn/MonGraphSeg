function plotImprovedTipNodes(originalEdges, originalPoints, improvedEdges, improvedPoints, options)
%PLOTIMPROVEDTIPNODES Visualizes original and improved tip segments of a plant skeleton.
%
%   This function overlays the original and improved graph representations
%   of a segmented plant skeleton. Stem and leaf segments are color-coded.
%
% INPUTS:
%   originalEdges     - Cell array: {node_indices, ..., segmentID} for the original tree
%   originalPoints    - [N x 3] or [N x ≥4] matrix: original skeleton points
%   improvedEdges     - Same structure as originalEdges, for the improved version
%   improvedPoints    - Same as originalPoints, for the improved version
%   options.plot_enabled - Flag to enable or disable plotting

    if ~options.plot_enabled
        return;
    end

    figure('Name', 'Improved Tips');


    % Extract segment labels from original edges
    segment_ids = cell2mat(originalEdges(:,4));
    maxSegmentID = max(segment_ids);
    colors = distinguishable_colors(maxSegmentID * 2);  % Color pool

    % Initialize legend handles
    hStem = [];
    hLeaf = [];

    % --- Plot improved tips
    for i = 1:size(improvedEdges,1)
        nodeIDs = improvedEdges{i,1};
        segmentID = segment_ids(i);  % use original ID for consistency
        color = colors(segmentID + size(improvedEdges,1), :);  % shift color index

        if segmentID > 1  % Leaf
            h = plot3(improvedPoints(nodeIDs,1), ...
                      improvedPoints(nodeIDs,2), ...
                      improvedPoints(nodeIDs,3), ...
                      'LineWidth', 5, 'Color', color);
            if isempty(hLeaf)
                hLeaf = h;
            end
        else  % Stem
            h = plot3(improvedPoints(nodeIDs,1), ...
                      improvedPoints(nodeIDs,2), ...
                      improvedPoints(nodeIDs,3), ...
                      'LineWidth', 5, 'Color', color);
            if isempty(hStem)
                hStem = h;
            end
        end
            hold on;
    end

    % --- Plot original paths (in same color scheme for comparison)
    for i = 1:size(originalEdges,1)
        nodeIDs = originalEdges{i,1};
        segmentID = segment_ids(i);
        color = colors(segmentID, :);

        if segmentID > 1
            h = plot3(originalPoints(nodeIDs,1), ...
                      originalPoints(nodeIDs,2), ...
                      originalPoints(nodeIDs,3), ...
                       'LineWidth', 2, 'Color', color);
        else
            h = plot3(originalPoints(nodeIDs,1), ...
                      originalPoints(nodeIDs,2), ...
                      originalPoints(nodeIDs,3), ...
                      'LineWidth', 2, 'Color', color);
        end
    end

    % Final plot formatting
    grid on;
    axis equal;
    xlabel('X [mm]'); ylabel('Y [mm]'); zlabel('Z [mm]');
    title('Improved Tip Segments');

    if exist('addAxis_Local', 'file')
        addAxis_Local();  % Optional axis helper
    end

    % Legend
    legend([hStem, hLeaf], {'Stem', 'Leaf'}, 'Location', 'best');

    hold off;
end
