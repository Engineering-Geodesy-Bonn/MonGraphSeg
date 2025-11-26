function bz_points_leaf = deCasteljauLeaf(bezierPts_leaf, intervals_leaf, ...
    junction_leaf, leaf_values_xyz, temp_BK)
% SPLITBEZIERSEGMENTFORLEAF Splits a leaf Bézier curve at the closest point to a leaf node.
%
% Inputs:
%   bezierPts_leaf   - [numSegments*3 x 3] control points for the full leaf Bézier curve
%   intervals_leaf   - global parameter values for the Bézier segments
%   junction_leaf    - index (from the tip toward the base) of the leaf point to project
%   leaf_values_xyz  - [N x 4] matrix of (x, y, z, segment index) values for leaf points
%   temp_BK          - [1 x 3] the stem intersection point used as new starting point
%
% Output:
%   bz_points_leaf   - [M x 3] new Bézier control points for the leaf after splitting

    % Compute the segment index ks (from bottom up, hence reverse indexing)
    ks = leaf_values_xyz(junction_leaf, 4);

    % Get parameter bounds for this Bézier segment
    u = intervals_leaf(ks);
    t = intervals_leaf(ks + 1);

    % Control points for the segment
    P0 = bezierPts_leaf(3*(ks-1)+1, :);
    P1 = bezierPts_leaf(3*(ks-1)+2, :);
    P2 = bezierPts_leaf(3*(ks-1)+3, :);

    % Point to project
    target_point = leaf_values_xyz(junction_leaf, 1:3);

    % Bézier curve definition
    bezier_curve = @(t) (1 - t).^2 * P0 + 2 * (1 - t) .* t * P1 + t.^2 * P2;

    % Distance function to minimize
    distance_to_point = @(t) norm(bezier_curve(t) - target_point);

    % Find t that minimizes distance
    t_optimal = fminbnd(distance_to_point, 0, 1);

    % Convert to global parameter space
    u0 = t_optimal * (t - u) + u;
    beta = (u0 - u) / (t - u);

    % De Casteljau steps to split Bézier segment
    P01 = (1 - beta) * P0 + beta * P1;
    P12 = (1 - beta) * P1 + beta * P2;
    P012 = (1 - beta) * P01 + beta * P12;

    % New control points from [u0, t], starting at stem intersection
    P_new0_S = temp_BK;  % intersection with stem
    P_new1_S = P12;
    P_new2_S = P2;

    bez_punkte = [P_new0_S; P_new1_S; P_new2_S];

    % Append remaining Bézier segments after the current one
    remaining_points = bezierPts_leaf((3 * ks + 1):end, :);

    % New list of Bézier control points for the leaf
    bz_points_leaf = [bez_punkte; remaining_points];
end
