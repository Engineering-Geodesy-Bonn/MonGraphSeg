function plotTreeAndRemovedEdges(skel_points_plant, skel_points_tree, overallEdges_plant, overallEdges_tree,options)
% plotTreeAndRemovedEdges
% Visualizes removed edges (in red) and tree edges (in green),
% and shows the tree structure with unique colors.
%
% Input:
%   skel_points_plant   - Nx3 matrix of 3D coordinates for the original skeleton points
%   skel_points_tree    - Mx3 matrix of 3D coordinates for the tree skeleton points
%   overallEdges_plant  - Cell array of edge index paths that were removed
%   overallEdges_tree   - Cell array of edge index paths that belong to the tree
if options.plot_enabled
    figure("Name","Removal Leaf-Stem-Cycles");

    % --- Subplot 1: Removed vs. tree edges ---
    subplot(1,2,1)

    % Plot removed edges in red
    for i = 1:length(overallEdges_plant)
        pathIndices = overallEdges_plant{i};
        plot3(skel_points_plant(pathIndices,1), ...
            skel_points_plant(pathIndices,2), ...
            skel_points_plant(pathIndices,3), ...
            'LineWidth', 3, 'Color', 'red');
        hold on;
    end

    % Plot tree edges in green
    for i = 1:length(overallEdges_tree)
        pathIndices = overallEdges_tree{i};
        plot3(skel_points_tree(pathIndices,1), ...
            skel_points_tree(pathIndices,2), ...
            skel_points_tree(pathIndices,3), ...
            'LineWidth', 3, 'Color', 'green');

    end


    % Dummy lines for legend
    h1 = plot3(nan, nan, nan, 'r', 'LineWidth', 3);
    h2 = plot3(nan, nan, nan, 'g', 'LineWidth', 3);
    legend([h1, h2], {'Removed edges', 'Tree edges'});

    axis equal;
    addAxis_Local;
    title('Removal of Leaf-Stem-Cycles');

    % --- Subplot 2: Colored tree edges ---
    subplot(1,2,2)

    colors = distinguishable_colors(length(overallEdges_tree));
    for i = 1:length(overallEdges_tree)
        pathIndices = overallEdges_tree{i};
        plot3(skel_points_tree(pathIndices,1), ...
            skel_points_tree(pathIndices,2), ...
            skel_points_tree(pathIndices,3), ...
            'LineWidth',3, 'Color', colors(i,:));
        hold on;
    end


    axis equal;
    addAxis_Local;
    title('Tree');
end
end
