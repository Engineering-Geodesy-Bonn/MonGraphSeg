function [points_skel] = Skeleton_function(ptCloud_all, A_options)
% Skeleton_function - Extract a skeleton from a 3D plant point cloud
%
% Important Note:
%   This function is based on external code (Cao, Junjie, et al. "Point cloud skeletons via laplacian based contraction." 2010 Shape Modeling International Conference. IEEE, 2010.)
%   and is not originally developed by the current author.
%
% Syntax:
%   points_skel = Skeleton_function(ptCloud_all, A_options)
%
% Inputs:
%   ptCloud_all - (Nx3 or NxD array) Full point cloud data (only the first three columns are used for (X, Y, Z) coordinates)
%   A_options   - Structure containing options for plotting (requires field 'plots_on')
%
% Output:
%   points_skel - (Mx3 array) Extracted and resampled skeleton points
%
% Description:
%   This function processes a given point cloud by normalizing it, downsampling it,
%   and applying a mesh contraction method to extract its structural skeleton.
%   The result is then resampled for more uniform distribution.
%   If plotting is enabled, the resulting skeleton is visualized.

    % Settings for skeleton computation
    options.USING_POINT_RING = GS.USING_POINT_RING;

    % Calculate the bounding box of the original point cloud
    bbox = [min(ptCloud_all(:,1)), min(ptCloud_all(:,2)), min(ptCloud_all(:,3)), ...
            max(ptCloud_all(:,1)), max(ptCloud_all(:,2)), max(ptCloud_all(:,3))];

    % Downsample the point cloud to a 1mm³ voxel grid
    temp_ = pcdownsample(pointCloud(ptCloud_all(:,1:3)), "gridNearest", 1);
    
    % Keep only unique points after downsampling
    P.pts = unique(temp_.Location, "rows");

    % Normalize points to [0,1] space using the bounding box
    P.pts = GS.normalize(P.pts, bbox);
    P.npts = size(P.pts, 1);  % Number of points after normalization
    [P.bbox, P.diameter] = GS.compute_bbox(P.pts);  % Updated bounding box and diameter
    P.k_knn = GS.compute_k_knn(P.npts);  % Determine number of nearest neighbors (k)
    P.rings = compute_point_point_ring(P.pts, P.k_knn, []);  % Compute 1-ring neighborhood relations

    % Create a new figure if plotting is enabled
    if A_options.plot_enabled
        f = figure("Name", "Skeleton");
    else
        f = [];
    end

    % Perform Laplacian-based mesh contraction to extract the skeleton
    [P.cpts, ~, ~, ~, ~] = contraction_by_mesh_laplacian(P, options, f, A_options);

    % Denormalize the skeleton points back to the original coordinate system
    points_skel_all = denormalize(P.cpts, bbox);

    % Resample skeleton points to ensure a more uniform spatial distribution
    [points_skel, ~] = farthest_sampling_by_sphere(points_skel_all, 1);

    % Plot the final resampled skeleton (optional)
    if A_options.plot_enabled
        figure(f);
        subplot(2,2,4)
        scatter3(points_skel(:,1), points_skel(:,2), points_skel(:,3), 5, 'filled')
        axis equal
        addAxis_Local()
    end

end
