function [overallEdges_tree_panSeg, plantStartingNode] = correct_stem_leaf_classification(overallEdges_tree_pruned, skel_points_tree,params)
%CORRECT_STEM_LEAF_ORIENTATION Reassigns leaf and stem edges based on direction
%
% This function checks and corrects the orientation of stem and leaf edges
% in a skeleton tree structure of a plant, using direction fitting.
%
% INPUTS:
%   overallEdges_tree_pruned : Cell array of pruned tree edges (Nx3)
%   skel_points_tree         : Matrix of 3D skeleton point coordinates
%
% OUTPUTS:
%   overallEdges_tree_panSeg : Updated cell array of tree edges with corrected orientation
%   plantStartingNode        : Index of the starting node of the stem (usually root)


% Start with the pruned edges
overallEdges_tree_panSeg = overallEdges_tree_pruned;
if size(overallEdges_tree_pruned,1)>1
    % === LOWER COMPARISON: Stem begin vs. lowest leaf ===
    % Compare Z coordinate of leaf start and stem start to determine orientation
    if skel_points_tree(overallEdges_tree_panSeg{2,3}, 3) < skel_points_tree(overallEdges_tree_panSeg{2,2}, 3)

        % Get the coordinates of the leaf edge (first third, flipped to align direction)
        nodes_leaf = skel_points_tree(overallEdges_tree_panSeg{2,1}, :);
        nodes_leaf = flipud(nodes_leaf);

        % Get the coordinates of the corresponding stem segment
        nodes_stem_ids = overallEdges_tree_panSeg{1,1};

     

        nodes_stem_end_idx = find(nodes_stem_ids == overallEdges_tree_panSeg{2,2});
        nodes_stem = skel_points_tree(nodes_stem_ids(1:nodes_stem_end_idx), :);


        area_ofSeg = round(min(size(nodes_leaf,1),size(nodes_stem,1))*params.stem_leaf_area_considered);
        nodes_leaf = nodes_leaf(1:area_ofSeg, :);
        nodes_stem = nodes_stem(1:area_ofSeg, :);
        direction_leaf = fit_direction(nodes_leaf);
        direction_stem = fit_direction(nodes_stem);

           if length(overallEdges_tree_panSeg)==2
        nodes_after = skel_points_tree(nodes_stem_ids(nodes_stem_end_idx:end), :);
           else



        nodes_stem_end_idx_after = find(nodes_stem_ids == overallEdges_tree_panSeg{3,2});
     

        nodes_stem_end_idx = find(nodes_stem_ids == overallEdges_tree_panSeg{2,2});
               nodes_after = skel_points_tree(nodes_stem_ids(nodes_stem_end_idx:nodes_stem_end_idx_after), :);
        
           end
        direction_after = fit_direction(nodes_after);

        angle_leaf = acosd(dot(direction_leaf,[0,0,1]));
        angle_stem = acosd(dot(direction_stem,[0,0,1]));

        
        % If the leaf has a smaller angle (i.e., more vertical), the stem
        % part and the leaf parts are swap
        if angle_leaf < angle_stem
            temp_edge = overallEdges_tree_panSeg{1,1};
            new_stem = temp_edge(nodes_stem_end_idx+1:end);
            new_leaf = flipud(temp_edge(1:nodes_stem_end_idx));

            % Reassign the segments
            overallEdges_tree_panSeg{1,1} = [flipud(overallEdges_tree_panSeg{2,1}); new_stem];
            overallEdges_tree_panSeg{1,2} = overallEdges_tree_panSeg{1,1}(1);
            overallEdges_tree_panSeg{1,3} = overallEdges_tree_panSeg{1,1}(end);
            overallEdges_tree_panSeg{2,1} = new_leaf;
            overallEdges_tree_panSeg{2,2} = new_leaf(1);
            overallEdges_tree_panSeg{2,3} = new_leaf(end);
        end
    end

    % Save the starting node of the stem
    plantStartingNode = overallEdges_tree_panSeg{1,2};

    % === UPPER COMPARISON: Stem end vs. highest leaf ===
    % Take first third of the highest leaf edge
    nodes_leaf = skel_points_tree(overallEdges_tree_panSeg{end,1}, :);
   
    % Take last third of the stem segment (from starting index to end)
    nodes_stem_ids = overallEdges_tree_panSeg{1,1};
    nodes_stem_start_idx = find(nodes_stem_ids == overallEdges_tree_panSeg{end,2});
    nodes_stem = skel_points_tree(nodes_stem_ids(nodes_stem_start_idx:end), :);


area_ofSeg = round(min(size(nodes_leaf,1),size(nodes_stem,1))*params.stem_leaf_area_considered);
        nodes_leaf = nodes_leaf(1:round(area_ofSeg), :);
    direction_leaf = fit_direction(nodes_leaf);


    nodes_stem = nodes_stem(1:round(area_ofSeg), :);
    direction_stem = fit_direction(nodes_stem);



    nodes_before = skel_points_tree(nodes_stem_ids(1:nodes_stem_start_idx), :);
    direction_before = fit_direction(nodes_before);

    angle_leaf = acosd(dot(direction_leaf,direction_before));
    angle_stem = acosd(dot(direction_stem,direction_before));



    % If the leaf has a smaller angle (i.e., more vertical), the stem
    % part and the leaf parts are swap
    if angle_leaf < angle_stem
        temp_edge = overallEdges_tree_panSeg{1,1};
        new_stem = temp_edge(1:nodes_stem_start_idx-1);
        new_leaf = temp_edge(nodes_stem_start_idx:end);

        % Reassign segments
        overallEdges_tree_panSeg{1,1} = [new_stem; overallEdges_tree_panSeg{end,1}];
        overallEdges_tree_panSeg{1,3} = overallEdges_tree_panSeg{end,3};
        overallEdges_tree_panSeg{end,1} = new_leaf;
        overallEdges_tree_panSeg{end,3} = new_leaf(end);
    end
else
    % Save the starting node of the stem
    plantStartingNode = overallEdges_tree_panSeg{1,2};

end
end
