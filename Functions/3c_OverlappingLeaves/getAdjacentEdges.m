function adjacent_edges = getAdjacentEdges(cycle_nodes, idx)
%GETADJACENTEDGES Returns the two edges adjacent to a node in a circular cycle.
%
% INPUTS:
%   cycle_nodes - Vector of node indices forming a closed cycle
%   idx         - Index in cycle_nodes of the node of interest
%
% OUTPUT:
%   adjacent_edges - 2x2 matrix of adjacent edges [fromNode, toNode]

    if idx == 1
        % Node is at the beginning of the cycle — wrap around to the end
        adjacent_edges = [
            cycle_nodes(end), cycle_nodes(idx);
            cycle_nodes(idx+1), cycle_nodes(idx)
        ];
    elseif idx == length(cycle_nodes)
        % Node is at the end of the cycle — wrap around to the start
        adjacent_edges = [
            cycle_nodes(idx-1), cycle_nodes(idx);
            cycle_nodes(1),     cycle_nodes(idx)
        ];
    else
        % Node is in the middle — get previous and next neighbors
        adjacent_edges = [
            cycle_nodes(idx-1), cycle_nodes(idx);
            cycle_nodes(idx+1), cycle_nodes(idx)
        ];
    end
end
