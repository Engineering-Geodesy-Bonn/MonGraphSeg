function score = bestDiceDirection(labels_A, labels_B, L_A, L_B)
% Helper function: Computes best Dice score from labels_A to labels_B

    score = 0;

    for i = 1:length(L_A)
        % Binary mask for current label in labels_A
        mask_A = labels_A == L_A(i);
        dice_vals = zeros(length(L_B), 1);

        for j = 1:length(L_B)
            % Binary mask for current label in labels_B
            mask_B = labels_B == L_B(j);

            % Compute intersection and union
            intersection = sum(mask_A & mask_B);
            union = sum(mask_A) + sum(mask_B);

            % Avoid division by zero
            if union == 0
                dice_vals(j) = 0;
            else
                dice_vals(j) = (2 * intersection) / union;
            end
        end

        % Take the best match (maximum Dice value)
        score = score + max(dice_vals);
    end

    % Normalize by number of labels in L_A
    score = score / length(L_A);
end