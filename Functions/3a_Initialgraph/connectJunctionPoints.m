function overallEdges = connectJunctionPoints(updated_neighbors, sum_nh, overallEdges)
    % Select junction points with more than 2 neighbors
    neighbors_JP = updated_neighbors(sum_nh > 2, :);
    
    % Remove neighbors that are not themselves junction points
    s = neighbors_JP(:, 2:end);
    s(~ismember(s, neighbors_JP(:, 1))) = 0;
    neighbors_JP(:, 2:end) = s;

    % Initialize index for new edges
    index_oE = size(overallEdges, 1) + 1;

    % Add edges between junction points
    for i = 1:size(neighbors_JP, 1)
        row_junctionPoint = neighbors_JP(i, :);
        neighbors = row_junctionPoint(2:end);
        neighbors = neighbors(neighbors > 0);  % Remove zero entries

        for j = 1:length(neighbors)
            t = cell2mat(overallEdges(:, 2:3));
            [a_1, b_1] = ismember([row_junctionPoint(1), neighbors(j)], t, "rows");
            [a_2, b_2] = ismember([neighbors(j), row_junctionPoint(1)], t, "rows");

            length_criteria = true;

            if a_1
                t1 = overallEdges{b_1, 1};
                len1 = length(t1);
                if len1 == 2
                    length_criteria = false;
                end
            end

            if a_2
                t2 = overallEdges{b_2, 1};
                len2 = length(t2);
                if len2 == 2
                    length_criteria = false;
                end
            end

            % Add edge if it doesn't exist or if length criterion is met
            if (a_1 + a_2 == 0) || length_criteria
                overallEdges{index_oE, 1} = [neighbors(j); row_junctionPoint(1)];
                overallEdges{index_oE, 2} = neighbors(j);
                overallEdges{index_oE, 3} = row_junctionPoint(1);
                index_oE = index_oE + 1;
            end
        end
    end
end
