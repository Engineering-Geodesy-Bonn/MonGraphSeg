function [direction_vector] = fit_direction(nodes)
% FIT_STEM_DIRECTION fits a robust linear polynomial to 3D stem points
% and computes the orientation with respect to the vertical axis (z-axis).
%
% INPUT:
%   nodes           - Nx3 matrix of 3D coordinates representing stem points
%
% OUTPUT:
%   coefficients     - 3x2 matrix, each row contains [slope, intercept] for x, y, z
%   direction_vector - normalized direction vector of the fitted polynomial
%   angle_deg        - angle (in degrees) between direction vector and [0 0 1]

    % Extract x, y, z coordinates
    x = nodes(:,1);
    y = nodes(:,2);
    z = nodes(:,3);

    % Compute cumulative arc length as parameter t
    arc_length = [0; cumsum(sqrt(diff(x).^2 + diff(y).^2 + diff(z).^2))];

    % Normalize t for numerical stability
    t_normalized = (arc_length - mean(arc_length)) / std(arc_length);

    % Design matrix (here just the normalized t values)
    t_vector = t_normalized';

    % Fit ls linear models for each coordinate
    coeff_x = robustfit(t_vector, x, 'ols');
    coeff_y = robustfit(t_vector, y, 'ols');
    coeff_z = robustfit(t_vector, z, 'ols');

    % Collect parameters: each row is [slope, intercept]
    coefficients = [coeff_x(2:end)', coeff_x(1);
                    coeff_y(2:end)', coeff_y(1);
                    coeff_z(2:end)', coeff_z(1)];

    % Extract and normalize the direction vector (slopes of the polynomials)
    direction_vector = coefficients(:,1) / norm(coefficients(:,1));

    % Compute angle to vertical z-axis
    angle_deg = acosd(dot(direction_vector, [0, 0, 1]));
end
