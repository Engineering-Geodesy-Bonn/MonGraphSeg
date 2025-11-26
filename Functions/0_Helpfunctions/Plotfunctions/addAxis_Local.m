function addAxis_Local()
% ADDAXIS_LOCAL - Adds labeled coordinate axes to the current 3D plot
%
% Syntax:
%   addAxis_Local()
%
% Description:
%   Sets axis labels for local coordinate system visualization in millimeters.
%   Applies to the current axes object.

    xlabel('loc. X [mm]');
    ylabel('loc. Y [mm]');
    zlabel('loc. Z [mm]');
end