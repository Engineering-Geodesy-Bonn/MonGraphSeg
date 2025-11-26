function overallEdges_tree = segmentLeaves(overallEdges_tree, path_stem, edges_of_Stem)
% segmentLeaves performs leaf segmentation based on the stem path
% and removes stem edges from the graph to isolate leaf regions.
%
% Inputs:
%   overallEdges_tree - Cell array containing edge data (including EndNodes and segmentation labels)
%   path_stem         - Vector of node indices forming the main stem path
%   edges_of_Stem     - Vector of edge indices corresponding to stem edges
%
% Output:
%   overallEdges_tree - Updated with segmentation labels in column 4

% Step 1: Create graph without stem edges
graph_WithoutStem = graph(cell2mat(overallEdges_tree(:,2)), ...
                          cell2mat(overallEdges_tree(:,3)), ...
                          1:size(overallEdges_tree,1));

% Remove stem edges by their index in the Weight field
graph_WithoutStem = rmedge(graph_WithoutStem, ...
                            find(ismember(graph_WithoutStem.Edges.Weight, edges_of_Stem)));

% Step 2: Segment each leaf emerging from the stem
index_segmentation = 2;
for i = 1:length(path_stem)
    neighbors_nodesStem = neighbors(graph_WithoutStem, path_stem(i));

    for j = 1:length(neighbors_nodesStem)
        % Temporarily remove connections to all other neighbors
        subgraph_P_j = rmedge(graph_WithoutStem, path_stem(i), neighbors_nodesStem([1:j-1, j+1:end]));

        % Identify connected components
        components_P_j = conncomp(subgraph_P_j);

        % Find edges fully contained in the same component as the j-th neighbor
        components_Edge = [(components_P_j(graph_WithoutStem.Edges.EndNodes(:,1)))', ...
                           (components_P_j(graph_WithoutStem.Edges.EndNodes(:,2)))'];

        target_component = components_P_j(neighbors_nodesStem(j));
        mask_same_component = sum(components_Edge == target_component, 2) == 2;
        edge_ids = graph_WithoutStem.Edges.Weight(mask_same_component);

        % Assign segmentation index to those edges
        overallEdges_tree(edge_ids, 4) = {index_segmentation};
        index_segmentation = index_segmentation + 1;
    end
end

end