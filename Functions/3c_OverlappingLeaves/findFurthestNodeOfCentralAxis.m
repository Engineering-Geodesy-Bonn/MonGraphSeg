function [max_index] = findFurthestNodeOfCentralAxis(skel_points, node_indices, line_point, direction_vector)
%COMPUTEDISTANCESTOLINE Computes orthogonal distances from points to a line in 3D.
%
% INPUTS:
%   skel_points     - Nx3 matrix of 3D skeleton coordinates
%   node_indices    - Indices of the points to consider (e.g., from a cycle)
%   line_point      - A 1x3 vector defining a point on the reference line
%   direction_vector- A 1x3 vector representing the direction of the reference line
%
% OUTPUTS:
%   distances       - Vector of orthogonal distances from each selected point to the line
%   max_index       - Index (in node_indices) of the point with the maximum distance
   num_points = length(node_indices);
    distances = zeros(1, num_points);

    % Calculate distance from each point to the line
    for i = 1:num_points
        % Current point P from the skeleton
        P = skel_points(node_indices(i), 1:3);

        % Vector from line_point (A) to P
        PA = P - line_point;

        % Cross product of PA and direction_vector
        crossProd = cross(PA, direction_vector);

        % Compute the orthogonal distance to the line
        distances(i) = norm(crossProd) / norm(direction_vector);
    end

    % Find the index of the point with the maximum distance
    [~, max_index] = max(distances);
end