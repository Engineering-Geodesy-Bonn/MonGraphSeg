function [overallEdges_tree,edges_of_Stem,path_stem] = extractStemPath(overallEdges_tree, skel_points_tree, plantStartingNodes_tree)
% extractStemPath identifies the most likely stem path in a tree-like plant skeleton
% based on unbranching criteria using shortest paths and subgraph analysis.
%
% Inputs:
%   overallEdges_tree       - Cell array of edges (Path, Source, Target)
%   skel_points_tree        - Nx3 matrix of 3D skeleton point coordinates
%   plantStartingNodes_tree - Array of possible starting nodes (e.g., stem base)
%
% Outputs:
%   overallEdges_tree  - Updated cell array with 4th column marking stem edges (0 or 1)
%   edges_of_Stem      - Sequence of edge ID segmented as the stem


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

tree_graph = graph(EdgeTable);
l = unique(cell2mat(overallEdges_tree(:,2:3)));

tree_graph.Nodes.Coordinates = skel_points_tree(1:l(end),:);
terminal_nodes = find(degree(tree_graph) == 1);

% Step 2: Evaluate all stem candidates
stem_candidates = cell(size(plantStartingNodes_tree,1)*(length(terminal_nodes)-1), 5);
a = 1;
for i = 1:length(plantStartingNodes_tree)
    start_node = plantStartingNodes_tree(i);
    terminal_nodes_filtered = terminal_nodes(~ismember(terminal_nodes, start_node));

    for j = 1:length(terminal_nodes_filtered)
        end_node = terminal_nodes_filtered(j);
        [P, d_path] = shortestpath(tree_graph, start_node, end_node);

        % Remove the candidate stem path temporarily
        UG_without_stemCandidate = rmedge(tree_graph, P(1:end-1), P(2:end));

        % Check connected subbranches
        sum_unbranching_edges = 0;
        for k = 1:length(P)
            connected_dists = distances(UG_without_stemCandidate, P(k));
            connected_dists = connected_dists(~isinf(connected_dists));

            if max(connected_dists) > 0
                bins = conncomp(UG_without_stemCandidate);
                current_bin = bins(P(k));
                nodes_in_bin = find(bins == current_bin);
                subG = subgraph(UG_without_stemCandidate, nodes_in_bin);
                local_node = find(nodes_in_bin == P(k));

                max_branch_dists = distances(subG, local_node);
                [~, term_node] = max(max_branch_dists);
                [P_branch, ~] = shortestpath(subG, local_node, term_node);

                subG_reduced = rmedge(subG, P_branch(1:end-1), P_branch(2:end));
                d = distances(subG_reduced);
                d = max(d(~isinf(d(:))));

                sum_unbranching_edges = sum_unbranching_edges + d;
            end
        end

        % Store candidate information
        stem_candidates{a,1} = start_node;
        stem_candidates{a,2} = end_node;
        stem_candidates{a,3} = P;
        stem_candidates{a,4} = sum_unbranching_edges;
        stem_candidates{a,5} = d_path;
        a = a + 1;
    end
end

% Step 3: Select the best stem path based on unbranching metric
[~, idx_sort] = sortrows(cell2mat(stem_candidates(:,4:5)), [1 -2]);
stem_candidates = stem_candidates(idx_sort, :);
path_stem = stem_candidates{1,3};


% Special case: From plant starting node to plant starting node
if sum(skel_points_tree(path_stem(1:end-1),3)- skel_points_tree(path_stem(2:end),3)<0)>0
    if length(path_stem)>2
    if (tree_graph.Nodes.Coordinates(path_stem(end-1),3)) < (tree_graph.Nodes.Coordinates(path_stem(2),3))
        path_stem = fliplr(path_stem);
    end
    end
end


% Step 4: Mark stem path edges in overallEdges_tree
edgeIdx = arrayfun(@(i) findedge(tree_graph, path_stem(i), path_stem(i+1)), 1:length(path_stem)-1);
overallEdges_tree(:, 4) = {0};
overallEdges_tree(tree_graph.Edges.EdgeIndex(edgeIdx), 4) = {1};
edges_of_Stem = tree_graph.Edges.EdgeIndex(edgeIdx);


% Step 5: If two ground nodes are connected via the stem

end