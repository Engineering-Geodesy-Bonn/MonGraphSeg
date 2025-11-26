function eval_row = evaluate_panoptic_segmentation(gt_labels, pred_labels, iou_threshold)
% EVALUATE_PANOPTIC_SEGMENTATION Computes evaluation metrics for panoptic segmentation.
%
% Parameters:
%   gt_labels     - Ground truth labels vector (1D array, integer labels, 0 = background)
%   pred_labels   - Predicted labels vector (1D array, integer labels, 0 = background)
%   iou_threshold - IoU threshold for matching (default: 0.5)
%
% Returns:
%   eval_row      - Row vector with [FN, FP, TP, mean_IoU, PQ, BestDice]

if nargin < 3
    iou_threshold = 0.5;
end

% Ensure labels are column vectors
gt_labels = gt_labels(:);
pred_labels = pred_labels(:);


% Get unique instance labels
unique_gt = unique(gt_labels);
unique_pred = unique(pred_labels);

% Initialize metrics
TP = 0;
FP = 0;
FN = 0;
sum_IoU = 0;

% Build IoU matrix
IoU_matrix = zeros(length(unique_gt), length(unique_pred));
for i = 1:length(unique_gt)
    gt_mask = gt_labels == unique_gt(i);
    for j = 1:length(unique_pred)
        pred_mask = pred_labels == unique_pred(j);
        intersection = sum(gt_mask & pred_mask);
        union = sum(gt_mask | pred_mask);
        if union > 0
            IoU_matrix(i, j) = intersection / union;
        end
    end
end

% Greedy matching using IoU
used_gt = false(size(unique_gt));
used_pred = false(size(unique_pred));
while true
    [max_IoU, idx] = max(IoU_matrix(:));
    if max_IoU < iou_threshold
        break;
    end
    [i, j] = ind2sub(size(IoU_matrix), idx);
    sum_IoU = sum_IoU + max_IoU;
    TP = TP + 1;
    IoU_matrix(i, :) = -1; % block this GT row
    IoU_matrix(:, j) = -1; % block this prediction column
    used_gt(i) = true;
    used_pred(j) = true;
end

% Calculate false negatives and false positives
FN = sum(~used_gt);
FP = sum(~used_pred);

% Calculate PQ and mean IoU
PQ = sum_IoU / (TP + 0.5 * FP + 0.5 * FN);
mean_IoU = sum_IoU / max(TP, 1); % avoid division by zero



% Compute Best Dice score in both directions
BD_1 = bestDiceDirection(gt_labels, pred_labels, unique_gt, unique_pred);
BD_2 = bestDiceDirection(pred_labels, gt_labels, unique_pred, unique_gt);


% Return evaluation row
eval_row = [FN, FP, TP, mean_IoU, PQ, min(BD_1,BD_2)];
end
