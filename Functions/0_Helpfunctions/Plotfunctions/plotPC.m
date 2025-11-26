function plotPC(ptCloud_all, options)
% PLOTPC - Visualizes a 3D point cloud if plotting is enabled.
%
% Syntax:
%   plotPC(ptCloud_all, options)
%
% Inputs:
%   ptCloud_all - (Nx3 or NxD array) The point cloud data, where the first three columns
%                 represent X, Y, and Z coordinates.
%   options     - Structure containing configuration settings. Requires:
%                 * options.plot_enabled (Boolean) - Enables/disables plotting.
%
% Description:
%   This function generates a 3D visualization of a point cloud when 'plot_enabled'
%   is set to true. It utilizes the built-in pcshow function for rendering and
%   also integrates local coordinate axes using the addAxis_Local function.
%
% Example:
%   options.plot_enabled = true;
%   plotPC(pointCloudData, options);
%
% See also: pcshow, addAxis_Local

    % Verify if plotting is enabled before proceeding
    if isfield(options, 'plot_enabled') && options.plot_enabled
        % Create a new figure and set a descriptive name
        figure("Name", "Point Cloud Visualization");

        % Plot the first three columns as 3D coordinates
        pcshow(ptCloud_all(:, 1:3));
        
        % Add local coordinate axes for better spatial orientation
        addAxis_Local();

        axis equal;
    end
end
