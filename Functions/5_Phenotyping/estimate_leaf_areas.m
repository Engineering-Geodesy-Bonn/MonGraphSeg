function leaf_area = estimate_leaf_areas(ptCloud_all, panoptic_segmentation_pC, panopticModel)
%ESTIMATE_LEAF_AREAS Estimate the surface area of each leaf instance from a panoptic plant segmentation.
%
%   leaf_area = ESTIMATE_LEAF_AREAS(ptCloud_all, panoptic_segmentation_pC, panopticModel)
%
%   This function estimates the surface area of each leaf instance in a
%   segmented plant point cloud. For each instance, a 3D alpha shape is
%   constructed from the corresponding points, and the leaf surface area is
%   obtained as the surface area of this alpha shape.
%
%   To obtain a robust, globally consistent scale parameter, the function
%   first estimates a characteristic neighbour distance from a downsampled,
%   randomly sampled subset of foreground points using k-nearest neighbours.
%   This characteristic distance is then used to set a global alpha value
%   that controls the level of geometric detail in the alpha shapes.
%
%   Input:
%       ptCloud_all
%           N×3 matrix of 3D point coordinates.
%
%       panoptic_segmentation_pC
%           N×1 vector (or N×K with labels in column 1) assigning each
%           point an instance label. Label 1 is assumed to be background.
%
%       panopticModel
%           Structure or array describing each panoptic instance (e.g. leaves).
%           panopticModel(1) corresponds to the background class.
%
%   Output:
%       leaf_area
%           (M×1) vector of estimated surface areas, where
%           M = length(panopticModel) - 1.
%           leaf_area(i) contains the area of the instance with label (i+1).
%           The background (label 1) is not included and is implicitly zero.
%

% -------------------------------------------------------------------------
% 0) Initialization
% -------------------------------------------------------------------------
labels    = panoptic_segmentation_pC(:,1);          % instance label per point
nInst     = length(panopticModel) - 1;              % number of foreground instances
leaf_area = zeros(nInst, 1, 'double');              % preallocate output

% -------------------------------------------------------------------------
% 1) Estimate a global scale parameter from a downsampled random subset
% -------------------------------------------------------------------------
% Use only foreground points (labels >= 2) to estimate a characteristic
% neighbour distance. This serves as a global scale for the alpha parameter.
fgMask = labels >= 2;
X = ptCloud_all(fgMask, 1:3);

% Optional voxel-based downsampling to reduce computation.
pc_ds = pcdownsample(pointCloud(X), "gridAverage", 2);   % voxel size can be tuned
X = pc_ds.Location;

if size(X,1) < 3
    % Not enough foreground points to estimate a meaningful scale.
    return;
end

% Parameters (can be tuned depending on point cloud density and scale).
num_neighbors            = 10;    % number of nearest neighbours
alpha_scale_factor       = 2.0;   % scaling factor for the alpha radius
maxSamples               = 5000;  % maximum number of points used to estimate scale

% Random subset of downsampled foreground points (reduces computation time).
nSample   = min(maxSamples, size(X,1));
idxSample = randperm(size(X,1), nSample);
Xs        = X(idxSample, :);

% kNN on the subset; MATLAB internally builds a kd-tree once.
[~, D] = knnsearch(Xs, Xs, ...
    'K',        num_neighbors, ...
    'Distance', 'euclidean', ...
    'NSMethod', 'kdtree');

% Exclude the self-distance (first column) and compute the mean neighbour distance.
meanNeighborDist = mean(D(:,2:end), 'all');

% Global alpha parameter used for all instances.
alpha = alpha_scale_factor * meanNeighborDist;

% -------------------------------------------------------------------------
% 2) Group points by instance label (single pass over all points)
% -------------------------------------------------------------------------
% Restrict to valid foreground instances (labels 2..length(panopticModel)).
validMask   = labels >= 2 & labels <= length(panopticModel);
labelsValid = labels(validMask);
ptsValid    = ptCloud_all(validMask, 1:3);

if isempty(ptsValid)
    % No valid foreground points present.
    return;
end

% Map instance labels 2..N to compact group indices 1..G.
[~,~,grpIdx] = unique(labelsValid);                 % group index per point

% For each group (instance), store the linear indices of its points.
idxCell = accumarray(grpIdx, (1:numel(grpIdx))', [], @(x){x});

% -------------------------------------------------------------------------
% 3) Per-instance alpha-shape construction and surface area estimation
% -------------------------------------------------------------------------
for k = 1:numel(idxCell)
    idxPoints = idxCell{k};
    points_i  = ptsValid(idxPoints, :);

    % At least three non-collinear points are required to form a surface.
    if size(points_i,1) < 3
        continue;
    end

    % Construct a 3D alpha shape for the current instance.
    shp3D = alphaShape(points_i(:,1), points_i(:,2), points_i(:,3), alpha);

    % Compute the surface area of the alpha shape, interpreted as leaf area.
    leaf_area_i = surfaceArea(shp3D);

    % Map back to the instance index: leaf_area(1) corresponds to label 2,
    % leaf_area(2) to label 3, and so forth.
    leaf_area(labelsValid(idxPoints(1)) - 1) = leaf_area_i;
end
end
