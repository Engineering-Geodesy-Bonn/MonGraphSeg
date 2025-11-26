function azimuth_angle = estimate_leaf_azimuth_angles(panopticModel)
% estimate_leaf_azimuth_angles computes the azimuth angle (in degrees) of each leaf
% based on the direction from the first to the last point in 2D (XY-plane).
%
% Input:
% - panopticModel: cell array where each element (from index 2 onward) contains
%                  an Nx3 matrix representing the skeleton of a leaf or segment.
%
% Output:
% - azimuth_angle: (N-1)x1 vector of azimuth angles in degrees, measured clockwise from the Y-axis.

    azimuth_angle = zeros(length(panopticModel) - 1, 1); % Preallocate angle array

    for i = 2:length(panopticModel)
        % Get first and last point in XY-plane
        start = panopticModel{i}(1,1:2);
        ende  = panopticModel{i}(end,1:2);

        % Calculate normalized direction vector
        vector = ende - start;
        vector = vector / norm(vector);

        % Angle from Y-axis (clockwise convention)
        theta = acos(vector(2)); % angle between vector and Y-axis
        if vector(1) < 0
            theta = 2*pi - theta;
        end

        % Convert to degrees
        azimuth_angle(i-1) = theta * 180 / pi;
    end
end
