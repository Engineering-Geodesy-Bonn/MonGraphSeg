function panopticModel_lt = panopticModel2LeafTip(panopticModel)
%PANOPTICMODEL2LEAFTIP Converts a panoptic model into a leaf tip model.
%
%   panopticModel_lt = PANOPTICMODEL2LEAFTIP(panopticModel)
%
%   This function modifies a panoptic model to extract meaningful leaf tip segmentation.
%   The process involves determining segmentation points based on the minimum Euclidean
%   distance between individual point sets. Segmented portions are then merged to 
%   refine the leaf tip representation.
%
%   INPUT:
%       panopticModel - Cell array containing sets of 3D points (x, y, z coordinates).
%
%   OUTPUT:
%       panopticModel_lt - Modified cell array containing segmented leaf tip points.
%
%   PROCESS:
%   1. Copy input data to preserve structure.
%   2. Iterate over individual data subsets:
%      - Compute Euclidean distances between the current subset and the reference set.
%      - Find the closest point in the reference set.
%      - Merge the segment from the reference set with the current subset.
%   3. Update the reference set to retain unprocessed segments.

    % Create a copy of the input model
    panopticModel_lt = panopticModel;

    % Initialize reference index
    b = 1;

    % Iterate through all subsets starting from the second entry
    for i = 2:size(panopticModel, 1)
        % Compute pairwise Euclidean distances between the current subset's points
        % and the reference subset's points (considering only x, y, and z coordinates)
        distanceMatrix = pdist2(panopticModel{i, 1}(:, 1:3), panopticModel{1, 1}(:, 1:3));

        % Find the minimum distance and corresponding index in the reference set
        [~, a] = min(min(distanceMatrix));

        % Merge the reference segment (from index b to a) with the current subset
        panopticModel_lt{i, 1} = [panopticModel{1, 1}(b:a, :); panopticModel{i, 1}];

        % Update reference index for the next iteration
        b = a;
    end

    % Store remaining points from the reference subset in the first entry
    panopticModel_lt{1, 1} = panopticModel{1, 1}(b:end, :);

end
