function [direction_vector, start_point] = findMoreVerticalAxis(n1, n2, n3)
%FINDMOREVERTICALAXIS Determines which of two vectors is more aligned with the vertical (Z-axis).
%
% Given three 3D points, this function compares the verticality of vectors
% n2 - n1 and n3 - n1, and returns the unit vector that is more vertical.
%
% INPUTS:
%   n1 - 1x3 vector representing the common base point
%   n2 - 1x3 vector, second point forming the first direction
%   n3 - 1x3 vector, third point forming the second direction
%
% OUTPUTS:
%   direction_vector - The unit vector (v1 or v2) that is more vertical (closer to Z-axis)
%   start_point      - The starting point used (always n1)
%   angle1           - Angle of v1 with respect to the Z-axis (in degrees)
%   angle2           - Angle of v2 with respect to the Z-axis (in degrees)

    % Compute direction vectors
    v1 = n2 - n1;
    v2 = n3 - n1;

    % Compute angle to Z-axis (vertical) for both vectors
    angle1 = acosd(v1(3) / norm(v1));
    angle2 = acosd(v2(3) / norm(v2));

    % Choose the more vertical direction (smaller angle to Z-axis)
    if angle1 < angle2
        direction_vector = v1 / norm(v1);
    else
        direction_vector = v2 / norm(v2);
    end

    % Output start point
    start_point = n1;
end
