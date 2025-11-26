function [R_y] = ComputeR_y(phi_y)
% Rotationsmatrix um y-Achse
R_y = [ cos(phi_y) 0 sin(phi_y);
    0 1 0;
    -sin(phi_y) 0 cos(phi_y)];
end