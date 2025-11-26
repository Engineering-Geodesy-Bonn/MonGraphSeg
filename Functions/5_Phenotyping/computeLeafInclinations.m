function inclination = computeLeafInclinations(panopticModel)
%COMPUTELEAFINCLINATIONS Computes inclination angles between leaves and the stem.
%
%   inclination = COMPUTELEAFINCLINATIONS(panopticModel)
%
%   Input:
%       panopticModel - Cell array containing 3D points of each plant part.
%                       The first cell is assumed to be the stem.
%
%   Output:
%       inclination   - Vector of inclination angles (in degrees) between each leaf
%                       and the corresponding stem section.

    % Initialize inclination vector
    inclination = zeros(length(panopticModel) - 1, 1);

    % Loop through each leaf (starting from index 2)
    for i = 2:length(panopticModel)
        % Get current leaf points
        points_leaf = panopticModel{i};

        % Define leaf vector: from base to approx. 1/3 of the leaf
        vector_leaf = points_leaf(round(size(points_leaf,1)/3), 1:3) - points_leaf(1, 1:3);

        % Get stem points
        points_stem = panopticModel{1};

        % Determine stem vector depending on leaf position
        if i < length(panopticModel)
            % Use start of next leaf to find corresponding stem region
            start_next_leaf = panopticModel{i+1}(1, 1:3);
            [~, idx_end_stem] = min(pdist2(points_stem(:,1:3), start_next_leaf));
            vector_stem = points_stem(idx_end_stem, 1:3) - points_leaf(1, 1:3);
        else
            % For the last leaf: follow the stem upward
            [~, idx_start_stem] = min(pdist2(points_stem(:,1:3), points_leaf(1,1:3)));
            points_stem_above = points_stem(idx_start_stem:end, :);

            % Compute cumulative distance along stem
            cumDist = cumulativeDistance(points_stem_above);

            % Parameters for stem vector calculation
            stem_direction_distance_mm = 50;  % Distance along stem for direction vector [mm]
            
            % Define vector at specified distance, or to last point
            if cumDist(end) > stem_direction_distance_mm
                idx_ = find(cumDist > stem_direction_distance_mm, 1);
                vector_stem = points_stem_above(idx_, 1:3) - points_leaf(1, 1:3);
            else
                vector_stem = points_stem_above(end, 1:3) - points_leaf(1, 1:3);
            end
        end

        % Compute inclination angle in degrees between leaf and stem vectors
        inclination(i-1) = acosd(dot(vector_stem, vector_leaf) / ...
                              (norm(vector_stem) * norm(vector_leaf)));
    end
end
