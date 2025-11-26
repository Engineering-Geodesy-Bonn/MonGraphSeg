function plotPanSegPointCloud(ptCloud_all, instance_segmentation_pC, panoptic_model, options)
%PLOTPANSEGPOINTCLOUD Visualizes the panoptic segmentation of a plant point cloud.
%
%   This function displays:
%     - (Left) The input point cloud colored by instance segmentation
%     - (Right) The panoptic model consisting of the stem and leaves
%
% INPUTS:
%   ptCloud_all            - [N x 3(+)] matrix of all input points
%   instance_segmentation_pC - [N x 1] vector of instance IDs for each point
%   panoptic_model         - Cell array of [M_i x 3] curves (stem and leaves)
%   options.plots_on       - Boolean flag to enable/disable plotting

if ~options.plot_enabled
    return;
end

% --- Prepare figure and colors
figure('Name', 'Panoptic Segmented Point Cloud');
colors = distinguishable_colors(size(panoptic_model, 1) + 2);

%% --- Subplot 1: Segmented point cloud with overlaid model
subplot(1, 2, 1);


% Downsampling parameters for visualization
downsample_step = 50;  % Plot every 50th point for performance
point_size = 10;       % Size of scatter points

sampled_points = 1:downsample_step:size(ptCloud_all,1);
% Plot colored point cloud by instance ID
scatter3(ptCloud_all(sampled_points,1), ...
    ptCloud_all(sampled_points,2), ...
    ptCloud_all(sampled_points,3), ...
    point_size, ...
    colors(instance_segmentation_pC(sampled_points,1), :), ...
    'filled');
hold on;

% Plot stem curve (assumed to be instance 1)
plot3(panoptic_model{1}(:,1), ...
    panoptic_model{1}(:,2), ...
    panoptic_model{1}(:,3), ...
    'Color', colors(1,:), 'LineWidth', 5);

% Plot all leaf curves
for i = 2:numel(panoptic_model)
    plot3(panoptic_model{i}(:,1), ...
        panoptic_model{i}(:,2), ...
        panoptic_model{i}(:,3), ...
        'Color', colors(i,:), 'LineWidth', 3);
end

axis equal;
grid on;
if exist('addAxis_Local', 'file')
    addAxis_Local();
end
view(3)

%% --- Subplot 2: Panoptic model only (no points)
subplot(1, 2, 2);
% Plot stem
plot3(panoptic_model{1}(:,1), panoptic_model{1}(:,2), panoptic_model{1}(:,3), 'Color', colors(1,:),'LineWidth',5);
hold on;

% Plot leaves
for i = 2:numel(panoptic_model)
    plot3(panoptic_model{i}(:,1), ...
        panoptic_model{i}(:,2), ...
        panoptic_model{i}(:,3), ...
        'Color', colors(i,:), 'LineWidth', 3);
end

axis equal;
grid on;
title('Panoptic Model');
xlabel('X [mm]'); ylabel('Y [mm]'); zlabel('Z [mm]');
if exist('addAxis_Local', 'file')
    addAxis_Local();
end

end
