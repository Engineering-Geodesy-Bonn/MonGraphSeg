function [R_x] = ComputeR_x(phi_x)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
R_x = [ 1 0 0;
    0 cos(phi_x) -sin(phi_x);
    0 sin(phi_x) cos(phi_x)];
end