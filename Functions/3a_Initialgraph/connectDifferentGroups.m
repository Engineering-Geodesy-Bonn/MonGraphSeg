function nh_new = connectDifferentGroups(veraendertePunkte, nh_, nh_new, translation)
% connectDifferentGroups - Connect different groups of junction points if neighbor relationships exist
%
% Syntax:
%   nh_neu = connectDifferentGroups(veraendertePunkte, nh_, nh_neu, uebersetzung)
%
% Inputs:
%   veraendertePunkte - (Nx3 array) [logicalFlag, groupID, pointID]
%                       - logicalFlag: 1 if the point is considered, 0 otherwise
%                       - groupID: ID of the group
%                       - pointID: original point index
%   nh_               - (PxQ array) Original neighborhood matrix (before modification)
%   nh_neu            - (PxQ array) Updated neighborhood matrix
%   uebersetzung      - (Px2 array) Mapping [oldIndex, newIndex] between old and new points
%
% Output:
%   nh_neu            - (PxQ array) Updated neighborhood matrix with cross-group connections added
%
% Description:
%   For every pair of different groups, this function checks if points across groups 
%   are neighboring each other. If so, it connects their corresponding new points
%   in the updated neighborhood matrix nh_neu.

    % Only consider valid points
    veraendertePunkte = veraendertePunkte(logical(veraendertePunkte(:,1)), :);

    % Find all unique groups
    unique_groups = unique(veraendertePunkte(:,2));

    % Loop over each pair of different groups
    for i = 1:length(unique_groups)
        points_group1 = veraendertePunkte(veraendertePunkte(:,2) == unique_groups(i), 3);
        
        for j = i+1:length(unique_groups)
            points_group2 = veraendertePunkte(veraendertePunkte(:,2) == unique_groups(j), 3);
            
            % Precompute neighborhood masks once
            neighbors_group1 = nh_(points_group1, 2:end);

            
            % Check for connections between groups
            for k = 1:numel(points_group2)
                % Find points in group1 that are neighbors with point k in group2
                mask = any(neighbors_group1 == points_group2(k), 2);
                connected_points = points_group1(mask);
                
                % If there is at least one connection
                if ~isempty(connected_points)
                    for temp = connected_points'
                        % Connect temp ↔ points_group2(k) if not already connected
                        temp_new = translation(temp,2);
                        point2_new = translation(points_group2(k),2);
                        
                        % Check and update neighbor for temp_new
                        neighbors_temp = nh_new(nh_new(:,1) == temp_new, 2:end);
                        neighbors_temp = neighbors_temp(neighbors_temp > 0);
                        if ~ismember(point2_new, neighbors_temp)
                            nh_new(nh_new(:,1) == temp_new, numel(neighbors_temp) + 2) = point2_new;
                        end
                        
                        % Check and update neighbor for point2_new
                        neighbors_point2 = nh_new(nh_new(:,1) == point2_new, 2:end);
                        neighbors_point2 = neighbors_point2(neighbors_point2 > 0);
                        if ~ismember(temp_new, neighbors_point2)
                            nh_new(nh_new(:,1) == point2_new, numel(neighbors_point2) + 2) = temp_new;
                        end
                    end
                end
            end
        end
    end

end
