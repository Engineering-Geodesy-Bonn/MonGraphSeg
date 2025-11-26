function cycle_lengths = computeCycleLengths(graph_B, cycles, overallEdges_plant, skel_points_plant)
%COMPUTECYCLELENGTHS Computes the lengths of cycles and self-loops in a graph.
%
% INPUTS:
%   graph_B              - A MATLAB graph object with 3D coordinates in graph_B.Nodes.Coordinates
%   cycles               - Cell array containing node indices forming cycles
%   overallEdges_plant   - Cell array mapping edge weights to index sequences
%   skel_points_plant    - Array of 3D points representing the plant skeleton
%
% OUTPUT:
%   cycle_lengths        - Array of calculated cycle lengths

    cycle_lengths = [];

    % Iterate through each cycle
    for i = 1:length(cycles)
        cycle = cycles{i};
        total_length = 0;

        % Compute the total length of the cycle
        for j = 1:length(cycle)-1
            if j == length(cycle)
                next_node = cycle(1);  % Close the cycle
            else
                next_node = cycle(j + 1);
            end

            % Find edge index and extract the associated segment
            edge_idx = findedge(graph_B, cycle(j), next_node);
            edge_weight = graph_B.Edges.Weight(edge_idx);
            edge_points_idx = cell2mat(overallEdges_plant(edge_weight));

            % Calculate length using cumulative distance
            segment_points = skel_points_plant(edge_points_idx, 1:3);
            distances = cumulativeDistance(segment_points);
            total_length = total_length + max(distances);
        end

        % Store the cycle length
        cycle_lengths(i) = total_length;
    end


end
