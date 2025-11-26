function plotPanopticEvaluation(panopticModel_lt, ptCloud_all, panoptic_segmentation_pC_lT, options)
% PLOTPANOPTICEVALUATION - Visualizes panoptic segmentation results with consistent colors.
%
% Syntax:
%   plotPanopticEvaluation(panopticModel_lt, ptCloud_all, panoptic_segmentation_pC_lT, options)
%
% Inputs:
%   panopticModel_lt - Cell array containing segmented leaf tip points.
%   ptCloud_all - Matrix of point cloud data including ground truth labels.
%   panoptic_segmentation_pC_lT - Matrix containing predicted labels.
%   options - Struct with evaluation parameters (e.g., column index for ground truth labels).
%
% Description:
%   This function generates a figure with three subplots:
%   1. The segmented panoptic model, showing the stem and leaf curves.
%   2. The ground truth point cloud data.
%   3. The predicted segmentation results.
%
%   Colors are assigned consistently across all subplots to ensure a uniform representation.
%
% Example:
%   plotPanopticEvaluation(panopticModel, pointCloudData, segmentedData, options);
%
% See also: scatter3, plot3

if options.plot_enabled
    % Create a figure for evaluation
    figure("Name", "Evaluation");

    % Define consistent colors for all subplots
    numInstance = size(panopticModel_lt, 1);
    colors = hsv(numInstance); 

    % ----- Subplot 1: Panoptic Model - Leaf Tip -----
    subplot(1,3,1);
    
    
    % Plot the stem (first entry in the cell array)
    plot3(panopticModel_lt{1}(:,1), ...
          panopticModel_lt{1}(:,2), ...
          panopticModel_lt{1}(:,3), ...
          'k', 'LineWidth', 5);
            hold on;

    % Plot the leaf curves with consistent colors
    for i = 2:numInstance
        plot3(panopticModel_lt{i}(:,1), ...
              panopticModel_lt{i}(:,2), ...
              panopticModel_lt{i}(:,3), ...
              'LineWidth', 3, 'Color', colors(i,:));
    end

    grid on;
    axis equal;
    addAxis_Local(); % Ensure this function is defined elsewhere
    title("Panoptic Model - Leaf Tip");

    % ----- Subplot 2: Ground Truth -----
    subplot(1,3,2);
    
    % Downsampling parameters for visualization
    downsample_step = 50;  % Plot every 50th point for performance
    point_size = 20;       % Size of scatter points
    
    colors_gt = lines(max(ptCloud_all(1:downsample_step:end, options.gt_column_index))+1); 

    % Scatter plot of ground truth data using the same colors
    scatter3(ptCloud_all(1:downsample_step:end, 1), ...
             ptCloud_all(1:downsample_step:end, 2), ...
             ptCloud_all(1:downsample_step:end, 3), ...
             point_size, colors_gt(ptCloud_all(1:downsample_step:end, options.gt_column_index)+1,:), 'filled');

    axis equal;
    title("Ground Truth");

    % ----- Subplot 3: Predicted Segmentation -----
    subplot(1,3,3);
    colors_pred = parula(numInstance+1); 

    % Scatter plot of predicted segmentation using the same colors
    scatter3(ptCloud_all(1:downsample_step:end, 1), ...
             ptCloud_all(1:downsample_step:end, 2), ...
             ptCloud_all(1:downsample_step:end, 3), ...
             point_size, colors_pred(panoptic_segmentation_pC_lT(1:downsample_step:end, 1),:), 'filled');

    axis equal;
    title("Result MonGraphSeg");
end
end
