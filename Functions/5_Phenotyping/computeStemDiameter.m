function diameter_mm = computeStemDiameter(panopticModel, panoptic_segmentation_pC, ptCloud_all, ds)
%COMPUTESTEMDIAMETER Computes the stem diameter based on panoptic segmentation and 3D point cloud data.
%
% INPUTS:
%   panopticModel            - Cell array containing panoptic segments (first element is stem)
%   panoptic_segmentation_pC - Nx3 array: column 1 = class label, column 3 = segment ID
%   ptCloud_all              - Nx3 array of all point cloud coordinates
%   ds                       - Distance in mm to group along the stem (e.g., 10 mm)
%
% OUTPUT:
%   diameter_mm              - Estimated median stem diameter in millimeters

% Find all stem point indices and their section labels
stem_indices = find(panoptic_segmentation_pC(:,1) == 1);
stem_section_ids = panoptic_segmentation_pC(stem_indices,3);
stem_points_xyz = ptCloud_all(stem_indices,1:3);
stem_model = panopticModel{1};

% If leaves exist, cut stem model up to the closest point to the last leaf
if size(panopticModel,1) > 1
    last_leaf_model = panopticModel{end};
    [~, cut_idx] = min(pdist2(last_leaf_model(1,1:3), stem_model(:,1:3)));
    stem_model = stem_model(1:cut_idx,:);
end

% Cumulative distance along stem
cum_dist = cumulativeDistance(stem_model(:,1:3));
group_ids = floor(cum_dist / ds) + 1;
groups = unique(group_ids);

semi_axes = zeros(length(groups), 2);

% Process each stem section
for i = 1:length(groups)
    segment_ids = find(group_ids == groups(i));
    section_points = stem_points_xyz(ismember(stem_section_ids, segment_ids),:);

    start_pt = stem_model(segment_ids(1), 1:3);
    end_pt   = stem_model(segment_ids(end), 1:3);
    direction = end_pt - start_pt;

    % Rotate section to local XY plane
    phi_y = atan2(direction(1), direction(3));
    R_y = ComputeR_y(phi_y);
    rotated_v = inv(R_y) * direction';
    phi_x = atan2(rotated_v(2), rotated_v(3));
    R_x = ComputeR_x(phi_x);

    centered_pts = section_points - mean(section_points, 1);
    pts_rotated = (R_x * inv(R_y) * centered_pts')';


    % Fit ellipse to X-Y projection
    % fit_ellipse.m
    % Original function by Ohad Gal
    % Source:
    %   Ohad Gal, "fit_ellipse", MATLAB Central File Exchange
    %   https://www.mathworks.com/matlabcentral/fileexchange/3215-fit_ellipse

    ell = fit_ellipse(pts_rotated(:,1), pts_rotated(:,2));
    if ~isempty(ell)
        if  ~strcmpi(ell.status,    'Hyperbola found')

            semi_axes(i,:) = [ell.a, ell.b];
        end
    end
end

diameter_mm = 2 * median(semi_axes(:));

end
