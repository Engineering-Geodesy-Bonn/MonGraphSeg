function panopticModel = cutPanopticModel(panopticModel, panoptic_segmentation_pC)
%CUTPANOPTICMODEL Trims each entry of the panopticModel cell array
% based on the segmentation information in panoptic_segmentation_pC.
%
% Inputs:
%   panopticModel - Cell array where each cell contains a matrix
%   panoptic_segmentation_pC - Nx3 matrix, where:
%       Column 1: Index of the corresponding panopticModel{i}
%       Column 3: Index within the matrix to keep (max used)
%
% Output:
%   panopticModel - The trimmed cell array, where each matrix is
%                   cropped to the maximum referenced row index

    for i = 1:numel(panopticModel)
        % Extract all rows of panoptic_segmentation_pC referencing this model entry
        mask = panoptic_segmentation_pC(:,1) == i;
        
        % Only cut if there are valid references
        if any(mask)
            maxIndex = max(panoptic_segmentation_pC(mask, 3));
            panopticModel{i} = panopticModel{i}(1:maxIndex+1, :);
        else
            % Optional: empty or skip model if not referenced at all
            panopticModel{i} = [];
        end
    end
end
