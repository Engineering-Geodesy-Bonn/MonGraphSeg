function parametrized_model = buildPanopticModel(overallEdges_tree_pruned, skel_points_tree, A_parameter)
% BUILDPANOPTICMODEL Fits a panoptic model (stem + leaves) using Bézier curves.
%   Returns a cell array of parametrized 3D curves.

    % Parameters for Bézier curve evaluation
    num_bezier_sample_points = 100;  % High-resolution sampling for smooth curves

% --- Fit stem with Bézier segments and C1 continuity
stem_points = skel_points_tree(overallEdges_tree_pruned{1,1}, 1:4);

for i = 1:length(stem_points)

    % Get coordinates of the current node and the Graph B nodes along the path
    node_xyz = stem_points(i:end, 1:3);
    [~,max_id] = max(node_xyz(:,3));

    vector = node_xyz(2:max_id, 1:3) - node_xyz(1,1:3);
    angles = acosd(vector(:,3) ./ vecnorm(vector, 2, 2));
    % If all direction vectors point generally upwards (within angle threshold)
    if all(angles < A_parameter.ground_angle_threshold_deg)
        break
    end
end

stem_points =stem_points(i:end,:);

[bezierPts_stem, ~, intervals_stem, intervals_] = fitBezierWithContinuity(stem_points, A_parameter);

% --- Compute cumulative distance for parameterization
t_stem = cumulativeDistance(stem_points(:, 1:3));

% --- Evaluate Bézier curve at stem sampling points
intervals_(end) = intervals_(end) + 1; % for evaluateBezierAtT compatibility
stem_xyz_adj = evaluateBezierAtT(bezierPts_stem, intervals_, t_stem);
stem_xyz_adj(:, 5) = stem_points(:, 4); % Add node indices

% --- High-resolution stem evaluation for junction detection
num_stem_samples = round(length(t_stem) / (length(intervals_) - 1));
temp_t = linspace(0, 1, num_stem_samples);
stem_xyz_adj_high_resolution = evaluateQuadraticBezierSegments(bezierPts_stem, length(intervals_stem) - 1, temp_t);

% --- Initialize output
parametrized_model = cell(size(overallEdges_tree_pruned, 1), 1);
parametrized_model{1} = stem_xyz_adj_high_resolution;
junction_stem_overview = zeros(size(overallEdges_tree_pruned, 1),1);
% --- Process each leaf (from second branch onward)
for m = 2:size(overallEdges_tree_pruned, 1)
    % Extract 3D points: stem below junction + leaf
    junction_id = overallEdges_tree_pruned{m,2};
    stem_below = stem_xyz_adj(1:find(stem_xyz_adj(:,5)==junction_id), 1:3)';
    leaf = skel_points_tree(overallEdges_tree_pruned{m,1}, 1:3)';
    l = [stem_below, leaf];

    % Cumulative distance parameterization
    t_leaf = cumulativeDistance(l');

    % Bézier fitting
    [bezierPts_leaf, ~, intervals_leaf, intervals_] = fitBezierWithContinuity(l', A_parameter);
    intervals_(end) = intervals_(end) + 1;
    % High-resolution evaluation
    temp_t = equalArcLengthParam(bezierPts_leaf, num_bezier_sample_points);
    leaf_values_xyz = evaluateQuadraticBezierSegments(bezierPts_leaf, length(intervals_leaf)-1, temp_t);

    % --- Find junction between stem and leaf
    % Single pdist2 call for all pairwise distances, then extract minimum per leaf point
    dist_all = pdist2(leaf_values_xyz(:,1:3), stem_xyz_adj_high_resolution(:,1:3));
    dist_leaf_stem = flipud(min(dist_all, [], 2));
    junction_leaf = find(dist_leaf_stem < A_parameter.dist_leaf_to_stem_mm, 1);
    junction_leaf = size(leaf_values_xyz,1) -junction_leaf+1;
    % Reuse previous distance matrix for finding closest stem point
    [~, junction_stem] = min(dist_all(junction_leaf, :));
    junction_stem_overview(m) = junction_stem;

    % --- Apply De Casteljau splitting
    temp_BK = deCasteljauStem(bezierPts_stem, intervals_stem, junction_stem, stem_xyz_adj_high_resolution);
    bz_points_leaf = deCasteljauLeaf(bezierPts_leaf, intervals_leaf, junction_leaf, leaf_values_xyz, temp_BK);

    % --- Final high-resolution leaf representation
    temp_t = linspace(0, 1, length(t_leaf)/(length(intervals_)-1));
    leaf_values_xyz = evaluateQuadraticBezierSegments(bz_points_leaf, size(bz_points_leaf,1)/3, temp_t);

    parametrized_model{m} = leaf_values_xyz;
end

last_points_z = cell2mat(cellfun(@(c) c(end, 3), parametrized_model(:), 'UniformOutput', false));
% Sortieren
[~, idx_sorted] = sortrows([junction_stem_overview,last_points_z],[1,2]);

parametrized_model = parametrized_model(idx_sorted,:);



end