function plotPanopticModel(parametrized_model,A_options)
% PLOTPANOPTICMODEL Plots a 3D panoptic model with stem and leaf curves.
%
%   The first curve (index 1) is assumed to be the stem and is plotted in
%   black and thicker. All others are treated as leaves and plotted thinner.
if A_options.plot_enabled
    figure("Name","Panoptic Model");
    grid on;
    title('Panoptic Model', 'FontSize', 16, 'FontWeight', 'bold');

    % Plot the stem first (index 1)
    plot3(parametrized_model{1}(:,1), ...
        parametrized_model{1}(:,2), ...
        parametrized_model{1}(:,3), ...
        'k', 'LineWidth', 5);

    hold on;

    % Plot the leaf curves
    for i = 2:size(parametrized_model, 1)
        plot3(parametrized_model{i}(:,1), ...
            parametrized_model{i}(:,2), ...
            parametrized_model{i}(:,3), ...
            'LineWidth', 3);
    end
    axis equal
    addAxis_Local
end
end
