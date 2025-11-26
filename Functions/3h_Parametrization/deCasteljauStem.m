function temp_BK = deCasteljauStem(bezierPts_stem, intervals_stem, junction_stem, stem_xyz_adj_high_resolution)
% deCasteljauStem Projects a 3D point onto its closest point on a quadratic Bézier segment using De Casteljau's algorithm.
%
% Inputs:
%   bezierPts_stem               - [numSegments*3 x 3] control points of all Bézier segments
%   intervals_stem               - global parameter values for the Bézier segments
%   junction_stem                - index of the 3D point (e.g. from a stem) to project
%   stem_xyz_adj_high_resolution - function handle or matrix returning [x, y, z, segment index] for a given index
%
% Output:
%   temp_BK                      - [1 x 3] closest point on the Bézier curve to the input point

    % Get the Bézier segment index from the 4th column
    ks = stem_xyz_adj_high_resolution(junction_stem, 4);
    
    % Get parameter interval [u, t] for this segment
    u = intervals_stem(ks);
    t = intervals_stem(ks + 1);

    % Extract the control points for segment ks
    P0 = bezierPts_stem(3*(ks-1)+1, :);
    P1 = bezierPts_stem(3*(ks-1)+2, :);
    P2 = bezierPts_stem(3*(ks-1)+3, :);

    % Define the Bézier curve as a function of t in [0, 1]
    bezier_curve = @(t) (1 - t).^2 * P0 + 2 * (1 - t) .* t * P1 + t.^2 * P2;

    % Target point in 3D
    target_point = stem_xyz_adj_high_resolution(junction_stem, 1:3);

    % Define the objective function to minimize distance
    distance_to_point = @(t) norm(bezier_curve(t) - target_point);

    % Find the t that minimizes distance
    t_optimal = fminbnd(distance_to_point, 0, 1);

    % Map to global parameter domain
    u0 = t_optimal * (t - u) + u;
    beta = (u0 - u) / (t - u);

    % Apply De Casteljau algorithm to get the closest point
    P01 = (1 - beta) * P0 + beta * P1;
    P12 = (1 - beta) * P1 + beta * P2;
    temp_BK = (1 - beta) * P01 + beta * P12;
end
