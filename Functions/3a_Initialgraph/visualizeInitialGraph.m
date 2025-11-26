function visualizeInitialGraph(overallEdges, updated_skeleton_points, options)
% VISUALIZEINITIALGRAPH - Visualizes a 3D skeletal graph with color-coded edges.
%
% Syntax:
%   visualizeInitialGraph(overallEdges, updated_skeleton_points, options)
%
% Inputs:
%   overallEdges            - Cell array containing graph edge details:
%                             {1}: Indices of points forming an edge path
%                             {2}, {3}: Start and end point indices of the edge
%   updated_skeleton_points - Nx3 matrix of 3D coordinates representing skeleton points
%   options               - Structure containing visualization settings (requires 'plot_enabled' field)
%
% Description:
%   This function generates a figure with two subplots:
%   1. The left subplot visualizes the complete edge paths.
%   2. The right subplot visualizes only the start and end connections of edges.
%
%   Each edge path is color-coded for better differentiation using distinguishable colors.
%   The function also ensures equal axis scaling and overlays a local axis using addAxis_Local.
%
% Example:
%   visualizeInitialGraph(overallEdges, updated_skeleton_points, options);
%
% See also: plot3, axis, hold on, addAxis_Local

    % Ensure plotting is enabled before proceeding
    if isfield(options, 'plot_enabled') && options.plot_enabled
        % Create a figure window for visualization
        figure("Name", "Initial Graph");

        % Define a colormap with distinguishable colors for each edge
        colors = distinguishable_colors(length(overallEdges));

        % ----- Subplot 1: Full edge paths -----
        subplot(1,2,1);
        for i = 1:size(overallEdges,1)
            pathIndices = overallEdges{i,1}; % Extract node indices forming an edge path
            plot3(updated_skeleton_points(pathIndices,1), ...
                  updated_skeleton_points(pathIndices,2), ...
                  updated_skeleton_points(pathIndices,3), ...
                  'LineWidth', 3, 'Color', colors(i,:));
                    hold on;
        end

        axis equal;
        addAxis_Local(); % Add reference axes
        title('Full Edge Paths');

        % ----- Subplot 2: Start and End Connections -----
        subplot(1,2,2);
        for i = 1:size(overallEdges,1)
            endPoints = [overallEdges{i,2}; overallEdges{i,3}]; % Extract start and end indices
            plot3(updated_skeleton_points(endPoints,1), ...
                  updated_skeleton_points(endPoints,2), ...
                  updated_skeleton_points(endPoints,3), ...
                  'LineWidth', 3, 'Color', colors(i,:));
                    hold on;
        end
        axis equal;
        addAxis_Local(); % Add reference axes
        title('Start and End Points Only');
    end
end
