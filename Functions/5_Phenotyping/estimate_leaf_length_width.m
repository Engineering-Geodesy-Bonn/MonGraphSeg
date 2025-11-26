function leaf_length_width = estimate_leaf_length_width(panopticModel, panoptic_segmentation_pC)
% estimate_leaf_length_width computes estimated length and width for each leaf instance.
%
% Input:
% - panopticModel: cell array or structure where each element contains a Nx3 matrix 
%                  of skeleton or representative 3D points of a leaf.
% - panoptic_segmentation_pC: Nx2 matrix, where:
%     - Column 1 holds length
%     - Column 2 holds width.
%
% Output:
% - leaf_length_width: (N-1)x2 matrix where each row contains:
%     [estimated_leaf_length, estimated_leaf_width]
%   (First instance is stem)

    leaf_length_width = zeros(length(panopticModel)-1, 2);

    for i = 2:length(panopticModel)
        % Compute total arc length along the leaf skeleton or axis
        t_length = cumulativeDistance(panopticModel{i}(:,1:3));
        leaf_length_width(i-1,1) = t_length(end);

        % Estimate width as the maximum radial extent in segmentation data (doubled for full width)
        leaf_points_mask = panoptic_segmentation_pC(:,1) == i;
        max_radius = max(panoptic_segmentation_pC(leaf_points_mask, 2));
        leaf_length_width(i-1,2) = 2 * max_radius;
    end
end
