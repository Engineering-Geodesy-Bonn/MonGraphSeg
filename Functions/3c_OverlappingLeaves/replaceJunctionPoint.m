function [overallEdges_plant, overallEdges_plant_new] = replaceJunctionPoint( ...
    Graph, adjacent_edge, junction_point, new_node, ...
    overallEdges_plant, overallEdges_plant_new)
%REPLACEJUNCTIONPOINT Replaces a junction point in edge data with a new node.
%
% This function finds the edge in the graph specified by `adjacent_edge`,
% checks whether the junction point is stored at position 2 or 3 in the
% corresponding cell of `overallEdges_plant`, and replaces it with the new node.
% The change is also reflected in `overallEdges_plant_new`.
%
% INPUTS:
%   Graph                - MATLAB graph object (without overlaps)
%   adjacent_edge        - A 1x2 vector [fromNode, toNode] representing an edge
%   junction_point       - The node to be replaced
%   new_node             - The node that replaces the junction point
%   overallEdges_plant   - Cell array with original edge info (at least 3 columns)
%   overallEdges_plant_new - Cell array with updated edge point sequences
%
% OUTPUTS:
%   overallEdges_plant     - Updated edge definitions with the new node
%   overallEdges_plant_new - Updated point sequences with the new node inserted

    % Find the index of the edge in the graph
    edge_idx = Graph.Edges.Weight(findedge(Graph, adjacent_edge(1), adjacent_edge(2)));

    % Check whether the junction point is in the second or third column
    if overallEdges_plant_new{edge_idx, 2} == junction_point
        % Replace second column with new node
        overallEdges_plant_new{edge_idx, 2} = new_node;

        % Update new edge sequence (prepend new_node, skip original first point)
        overallEdges_plant_new{edge_idx, 1} = [new_node; overallEdges_plant_new{edge_idx, 1}(2:end)];
    else
        % Replace third column with new node
        overallEdges_plant_new{edge_idx, 3} = new_node;

        % Update new edge sequence (append new_node, skip original last point)
        overallEdges_plant_new{edge_idx, 1} = [overallEdges_plant_new{edge_idx, 1}(1:end-1); new_node];
    end
end
