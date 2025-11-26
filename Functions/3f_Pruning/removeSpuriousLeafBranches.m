function overallEdges_tree_concluded = removeSpuriousLeafBranches(overallEdges_tree, path_stem,skel_points_tree)
% removeSpuriousLeafBranches removes spurious (redundant) branches at the leaves
% of a tree graph structure by analyzing unbranching criteria
%
% INPUT:
%   overallEdges_tree : Cell array with columns {startNode, endNode, edgeID, segmentID}
%   path_stem         : Vector of node IDs that belong to the stem path
%
% OUTPUT:
%   overallEdges_tree : Updated cell array with spurious leaf branches removed

% Build the graph from the edge list (use edgeID as weights for identification)

% Step 1: Build edge list and compute weights
sources = cell2mat(overallEdges_tree(:,2));
targets = cell2mat(overallEdges_tree(:,3));
weight_edges = zeros(size(overallEdges_tree,1),1);

% Calculate edge weights using cumulative distance along the path
for i = 1:size(overallEdges_tree,1)
    path_points = skel_points_tree(cell2mat(overallEdges_tree(i,1)), :);
    weight_edges(i) = max(cumulativeDistance(path_points));
end

edgeIndices = (1:length(sources))';

% Create table for graph construction
EdgeTable = table([sources, targets], weight_edges, edgeIndices, ...
    'VariableNames', {'EndNodes', 'Weight', 'EdgeIndex'});

G = graph(EdgeTable);

edgesToRemove = [];

% Iterate through all segment IDs (excluding the main stem segment with ID 1)
for segID = 2:max(cell2mat(overallEdges_tree(:,4)))
    % Extract all nodes involved in this segment
    edgesInSegment = cell2mat(overallEdges_tree(cell2mat(overallEdges_tree(:,4)) == segID, 2:3));
    uniqueNodes = unique(edgesInSegment(:));

    % Get node degrees within this segment
    nodeDegrees = degree(G, uniqueNodes);
    nodeOverview = [uniqueNodes, nodeDegrees];


    % Remove if more than one node has degree 3 (indicates a branching artifact)
    if sum(nodeDegrees == 3) > 1
        edgeIndices = find(cell2mat(overallEdges_tree(:,4)) == segID);
        stemNode = uniqueNodes(ismember(uniqueNodes, path_stem));

        % Find the furthest leaf node from the stem node
        [~, maxDistIdx] = max(distances(G, stemNode, uniqueNodes));
        pathToKeep = shortestpath(G, stemNode, uniqueNodes(maxDistIdx));

        % Get the edge indices of the path to keep
        edgeIdxInPath = arrayfun(@(k) findedge(G, pathToKeep(k), pathToKeep(k+1)), 1:length(pathToKeep)-1);
        edgesToKeep = G.Edges.EdgeIndex(edgeIdxInPath);

        % Mark the remaining edges of the segment for removal
        edgesToRemove = [edgesToRemove; edgeIndices(~ismember(edgeIndices, edgesToKeep))];
    end
end

% Remove marked edges
overallEdges_tree(edgesToRemove, :) = [];


%
% Build the graph from the edge list (use edgeID as weights for identification)
G = graph(cell2mat(overallEdges_tree(:,2)), ...
    cell2mat(overallEdges_tree(:,3)), ...
    1:length(overallEdges_tree(:,3)));


overallEdges_tree_concluded = cell(max(cell2mat(overallEdges_tree(:,4))),4);
endNodes_overallEdges = cell2mat(overallEdges_tree(:,2:3));

temp_nodes = path_stem(1);
for j = 1:length(path_stem)-1
    if sum((ismember(endNodes_overallEdges(:,1:2),path_stem(j:j+1),"rows"))>0)% Right order
        id_edge = find(ismember(endNodes_overallEdges(:,1:2),path_stem(j:j+1),"rows"));
        nodes_leaf = cell2mat(overallEdges_tree(id_edge,1));
        temp_nodes = [temp_nodes;nodes_leaf(2:end)];
    else % wrong order
        id_edge = find(ismember(endNodes_overallEdges(:,[2,1]),path_stem(j:j+1),"rows"));
        nodes_leaf = cell2mat(overallEdges_tree(id_edge,1));
        nodes_leaf = flipud(nodes_leaf);
        temp_nodes = [temp_nodes;nodes_leaf(2:end)];
    end
end
overallEdges_tree_concluded{1,1} = temp_nodes;
overallEdges_tree_concluded{1,2} = path_stem(1);
overallEdges_tree_concluded{1,3} =  path_stem(end);
overallEdges_tree_concluded{1,4} = 1;


for segID = 2:max(cell2mat(overallEdges_tree(:,4)))
    edgeIndices = find(cell2mat(overallEdges_tree(:,4)) == segID);
    edgesInSegment = cell2mat(overallEdges_tree(cell2mat(overallEdges_tree(:,4)) == segID, 2:3));
    uniqueNodes = unique(edgesInSegment(:));

    stemNode = uniqueNodes(ismember(uniqueNodes, path_stem));

    % Find the furthest leaf node from the stem node
    [~, maxDistIdx] = max(distances(G, stemNode, uniqueNodes));

    nodes_Leaves = shortestpath(G, stemNode, uniqueNodes(maxDistIdx));
    temp_nodes =stemNode ;
    for j = 1:length(nodes_Leaves)-1
        if sum((ismember(endNodes_overallEdges(:,1:2),nodes_Leaves(j:j+1),"rows"))>0)% Right order
            id_edge = find(ismember(endNodes_overallEdges(:,1:2),nodes_Leaves(j:j+1),"rows"));
            nodes_leaf = cell2mat(overallEdges_tree(id_edge,1));
            temp_nodes = [temp_nodes;nodes_leaf(2:end)];
        else % wrong order
            id_edge = find(ismember(endNodes_overallEdges(:,[2,1]),nodes_Leaves(j:j+1),"rows"));
            nodes_leaf = cell2mat(overallEdges_tree(id_edge,1));
            nodes_leaf = flipud(nodes_leaf);
            temp_nodes = [temp_nodes;nodes_leaf(2:end)];
        end
    end
    overallEdges_tree_concluded{segID,1} = temp_nodes;
    overallEdges_tree_concluded{segID,2} = stemNode;
    overallEdges_tree_concluded{segID,3} =  uniqueNodes(maxDistIdx);
    overallEdges_tree_concluded{segID,4} = segID;
end


end
