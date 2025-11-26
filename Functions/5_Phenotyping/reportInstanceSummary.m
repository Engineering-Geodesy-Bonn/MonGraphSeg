function numberInstances = reportInstanceSummary(panopticModel, ground_existing)
% REPORTINSTANCESUMMARY - Summarizes the number of detected plant instances.
%
% Syntax:
%   numberInstances = reportInstanceSummary(panopticModel, ground_existing)
%
% Inputs:
%   panopticModel   - (NxD array or table) Each row corresponds to one detected leaf instance.
%   ground_existing - (Boolean) Indicates whether a soil instance is present (true/false).
%
% Outputs:
%   numberInstances - (1x3 vector) Counts of detected plant components:
%                     [Stem count, Leaf count, Ground count].
%
% Description:
%   This function analyzes the provided plant segmentation data and determines the number
%   of detected instances for three categories: Stem, Leaves, and Ground.
%
%   The counting logic follows:
%   - If ground exists, at one ground instance is recorded.
%   - If one or more plant instances exist, the first entry represents the stem.
%   - Remaining entries correspond to individual leaf instances.
%
% Example:
%   numInstances = reportInstanceSummary(panopticModel, true);
%
% See also: size

    % Initialize instance count vector [Stem, Leaves, Ground]
    numberInstances = zeros(1, 3); 

    % Check if ground is present
    if ground_existing
        numberInstances(1) = 1; % Stem always exists
        if size(panopticModel, 1) > 0
            numberInstances(2) = 1; % At least  the stem is there
            numberInstances(3) = size(panopticModel, 1) - 1; % Remaining instances as leaves
        end
    else
        if size(panopticModel, 1) > 0
            numberInstances(1) = 0; 
            numberInstances(2) = 1; % At least the stem is there
            numberInstances(3) = size(panopticModel, 1) - 1; % Remaining instances as leaves
        end
    end

end
