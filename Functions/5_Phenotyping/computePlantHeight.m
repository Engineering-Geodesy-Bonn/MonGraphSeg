function plant_height = computePlantHeight(panopticModel, ptCloud_all, panoptic_segmentation_pC, ground_existing)
%COMPUTEPLANTHEIGHT Computes the height of a plant from its panoptic model.
%
%   plant_height = COMPUTEPLANTHEIGHT(panopticModel, ptCloud_all, panoptic_segmentation_pC, ground_existing)
%
%   Inputs:
%       panopticModel            - Cell array containing 3D points of the plant (cell2mat-compatible).
%       ptCloud_all              - Full point cloud (Mx3 or MxN matrix), containing all scene points.
%       panoptic_segmentation_pC - Panoptic label for each point in ptCloud_all.
%       ground_existing          - Boolean flag indicating whether a ground plane exists.
%
%   Output:
%       plant_height             - Computed height of the plant.

    % Convert the panoptic model cell array to a numeric matrix
    points_panopticModel = cell2mat(panopticModel);

    % Find the highest point in Z-direction
    [~, max_idx] = max(points_panopticModel(:,3));
    highest_point = points_panopticModel(max_idx, 1:3);

    if ground_existing
        % Select the points with the maximum panoptic label (assumed to be ground)
        max_label = max(panoptic_segmentation_pC);
        points_ground = ptCloud_all(panoptic_segmentation_pC(:,1) == max_label, 1:3);

        % Fit a plane to the ground points
        plane_ground = pcfitplane(pointCloud(points_ground), 3);

        % Compute height as orthogonal distance from highest point to ground plane
        plant_height = abs(dot(plane_ground.Normal, highest_point) + plane_ground.Parameters(4));
    else
        % No ground: use lowest plant point as base
        [~, min_idx] = min(points_panopticModel(:,3));
        lowest_point = points_panopticModel(min_idx, 1:3);

        % Compute vertical distance between top and bottom
        plant_height = highest_point(3) - lowest_point(3);
    end
end
