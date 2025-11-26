function visualizeGroundRemoval(overallEdges_plant, overallEdges, skel_points_plant, updated_skeleton_points, options)
% VISUALIZEGROUNDREMOVAL - Visualizes the effect of ground node removal on a plant skeleton graph
%
% This function plots the full original skeleton (including ground) and the filtered plant structure
% (with ground-level nodes removed). It provides a visual comparison before and after processing.
%
% Inputs:
%   - overallEdges           : Cell array where each row contains:
%                                {1} = list of point indices along an edge (original skeleton)
%                                {2}, {3} = start and end indices of the edge
%   - overallEdges_plant     : Cell array like overallEdges, but filtered (ground removed)
%   - skel_points_plant      : Nx3 matrix of 3D coordinates for the filtered skeleton (plant only)
%   - updated_skeleton_points: Nx3 matrix of 3D coordinates for the full skeleton (before filtering)
%   - options              : Struct with visualization options, expects a field `plots_on` (boolean)
%
% Example usage:
%   visualizeGroundRemoval(overallEdges_plant, overallEdges, skel_points_plant, updated_skeleton_points, options)

if options.plot_enabled
    figure("Name", 'Initial vs. Filtered Graph');

    %% Plot 1: Original graph in red, filtered (plant) graph in green
    subplot(1,2,1)
    % Plot original full skeleton (red)
    for i = 1:size(overallEdges,1)
        pathIndices = overallEdges{i,1};
        plot3(updated_skeleton_points(pathIndices,1), ...
              updated_skeleton_points(pathIndices,2), ...
              updated_skeleton_points(pathIndices,3), ...
              'LineWidth', 3, 'Color', "red");
        hold on;
    end

    % Plot filtered skeleton (green, after ground removal)
    for i = 1:size(overallEdges_plant,1)
        pathIndices = overallEdges_plant{i,1};
        plot3(skel_points_plant(pathIndices,1), ...
              skel_points_plant(pathIndices,2), ...
              skel_points_plant(pathIndices,3), ...
              'LineWidth', 5, 'Color', "green");
        hold on;
    end

    axis equal
    addAxis_Local
    title('Ground Removal: Removed Ground (red) vs Plant edges (green)');

    %% Plot 2: Color-coded filtered plant graph
    subplot(1,2,2)
    Colors_ = distinguishable_colors(length(overallEdges_plant));
    for i = 1:size(overallEdges_plant,1)
        pathIndices = overallEdges_plant{i,1};
        plot3(skel_points_plant(pathIndices,1), ...
              skel_points_plant(pathIndices,2), ...
              skel_points_plant(pathIndices,3), ...
              'LineWidth', 3, 'Color', Colors_(i,:));
        hold on;
    end

    axis equal
    addAxis_Local
    title('Filtered Plant Graph (Color by Edge)');
end
end
