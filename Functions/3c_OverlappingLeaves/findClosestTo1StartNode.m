function closest_node = findClosestTo1StartNode(graph_obj, start_nodes, candidate_nodes)
%FINDCLOSESTTOSTARTNODE Finds the node from candidate_nodes with the shortest path to one start_node.
%
% INPUTS:
%   graph_obj       - A MATLAB graph or digraph object (e.g., UG_final_ohneKreise)
%   start_nodes     - Vector of node indices representing the start points (e.g., plantStartingNodes)
%   candidate_nodes - Vector of node indices to evaluate (e.g., aktuellerKreis)
%
% OUTPUT:
%   closest_node    - Node index from candidate_nodes with the shortest path to the start_nodes

    min_distance = inf;
    closest_node = NaN;

    % Iterate through each candidate node
    for j = 1:length(candidate_nodes)
        % Compute shortest path from any start_node to current candidate_node
        [~, distance] = shortestpath(graph_obj, start_nodes, candidate_nodes(j));

        % Keep track of the node with the minimum distance
        if distance < min_distance
            closest_node = candidate_nodes(j);
            min_distance = distance;
        end
    end
end
