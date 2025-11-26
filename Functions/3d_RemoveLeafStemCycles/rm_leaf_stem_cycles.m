function [overallEdges_tree, skel_points_tree, plantStartingNodes_tree] = rm_leaf_stem_cycles(overallEdges_plant, skel_points_plant, plantStartingNodes)
%RM_LEAF_STEM_CYCLES Removes leaf-stem cycles and extracts a topological tree structure from a plant skeleton.
%
% INPUTS:
%   overallEdges_plant      - [current_node x 3] cell array: {node_sequence, start_node, end_node}
%   skel_points_plant       - [M x 4] matrix: [X Y Z ID]
%   plantStartingNodes      - Indices of stem root nodes (typically a single node)
%
% OUTPUTS:
%   overallEdges_tree       - Cleaned subset of overallEdges_plant representing a tree
%   skel_points_tree        - Reindexed skeleton points used in the tree
%   plantStartingNodes_tree - Reindexed start node(s) in skel_points_tree

%% Step 1: Build initial graph
l = unique(cell2mat(overallEdges_plant(:,2:3)));
graph_B = graph(cell2mat(overallEdges_plant(:,2)), cell2mat(overallEdges_plant(:,3)), 1:length(overallEdges_plant(:,3)));
graph_B.Nodes.Coordinates = skel_points_plant(1:l(end),1:3);


% Remove self-loops
graph_B = rmedge(graph_B, find(graph_B.Edges.EndNodes(:,1) == graph_B.Edges.EndNodes(:,2)));



%% Step 2: Initialize tree growing from the plant starting node
queue = [];

% Select forst edges
current_node = plantStartingNodes(1);
e = find(sum(graph_B.Edges.EndNodes == current_node, 2), 1);
e_nodes = graph_B.Edges.EndNodes(e,:);
next_node = e_nodes(e_nodes ~= current_node);
processed_nodes = [current_node; next_node];
edges_tree = graph_B.Edges.Weight(e);
graph_B = rmedge(graph_B, e);


%% Step 3: Iteratively build the tree
% Unique nodes in the graph
all_nodes = unique([cell2mat(overallEdges_plant(:,2)); cell2mat(overallEdges_plant(:,3))]);
% Main loop to build tree
while length(processed_nodes) < length(all_nodes)
     end_nodes = graph_B.Edges.EndNodes;
    remove_mask = sum(ismember(end_nodes, processed_nodes), 2) == 2;
    graph_B = rmedge(graph_B, find(remove_mask));
    degree_k = degree(graph_B, next_node);

    % Case A
    if degree_k == 1
        current_node = next_node;
        e = find(sum(graph_B.Edges.EndNodes == current_node, 2), 1);
        e_nodes = graph_B.Edges.EndNodes(e,:);
        next_node = e_nodes(e_nodes ~= current_node);
        processed_nodes = [processed_nodes; next_node];
        edges_tree = [edges_tree; graph_B.Edges.Weight(e)];
        graph_B = rmedge(graph_B, e);

        % Case B
    elseif degree_k > 1
        ori_e = normalizeVec(graph_B.Nodes.Coordinates(current_node,1:3) - graph_B.Nodes.Coordinates(next_node,1:3));

        candidates = find(sum(graph_B.Edges.EndNodes == next_node, 2) > 0);
        l_temp = graph_B.Edges.EndNodes(candidates, :);
        l = l_temp(l_temp ~= next_node);

        Theta_q = zeros(size(l));
        for j = 1:length(l)
            ori_q = normalizeVec(graph_B.Nodes.Coordinates(l(j),1:3) - graph_B.Nodes.Coordinates(next_node,1:3));
            Theta_q(j) = acosd(dot(ori_q, ori_e));
        end

        [min_angle, idx_q] = min(abs(Theta_q - 180));
        idx_q = candidates(idx_q);

        if sum(abs(Theta_q - 180) == min_angle) > 1
            tied = find(abs(Theta_q - 180) == min_angle);
            edges_graph_ = graph_B.Edges.Weight(candidates(tied));
            row_sizes = cellfun(@(x) size(x,1), overallEdges_plant(edges_graph_));
            [~, idx_best] = min(row_sizes);
            idx_q = candidates(tied(idx_best));
        end

        add_edges =  graph_B.Edges.Weight(candidates(candidates ~= idx_q));
        row_sizes = cellfun(@(x) size(x,1), overallEdges_plant(add_edges));
        [~,id_sort] =   sort(row_sizes);
        add_edges = add_edges(id_sort);
        queue = [queue;add_edges];

        current_node = next_node;
        e = idx_q;
        e_nodes = graph_B.Edges.EndNodes(e,:);
        next_node = e_nodes(e_nodes ~= current_node);
        processed_nodes = [processed_nodes; next_node];
        edges_tree = [edges_tree; graph_B.Edges.Weight(e)];
        graph_B = rmedge(graph_B, e);

        % Case C
    elseif degree_k == 0
        queue = unique(queue, "stable");

        if isempty(queue)
            break;
        end

        [in_graph, edge_idx] = ismember(queue, graph_B.Edges.Weight);
        edge_idx = edge_idx(in_graph);
        queue = queue(in_graph);

        end_nodes_q = graph_B.Edges.EndNodes(edge_idx, :);
        to_remove = sum(ismember(end_nodes_q, processed_nodes), 2) == 2;
        graph_B = rmedge(graph_B, edge_idx(to_remove));
        queue(to_remove) = [];
        end_nodes_q(to_remove,:) = [];

        if isempty(queue)
            break;
        end

        e = find(graph_B.Edges.Weight == queue(1), 1);
        queue(1) = [];
        e_nodes = graph_B.Edges.EndNodes(e,:);
        current_node = e_nodes(ismember(e_nodes, processed_nodes));
        next_node = e_nodes(e_nodes ~= current_node);

        processed_nodes = [processed_nodes; current_node; next_node];
        edges_tree = [edges_tree; graph_B.Edges.Weight(e)];
        graph_B = rmedge(graph_B, e);
    end

    processed_nodes = unique(processed_nodes);
end

%% Step 4: Filter edges and rebuild graph

sortedEdges = sort(cell2mat(overallEdges_plant(:,2:3)),2);
sortedEdges = unique(sortedEdges,"rows");
graph_full = graph(sortedEdges(:,1),sortedEdges(:,2));
terminal_nodes = find(degree(graph_full) == 1);


graph_full = graph(cell2mat(overallEdges_plant(:,2)), ...
    cell2mat(overallEdges_plant(:,3)), ...
    1:length(overallEdges_plant(:,3)));


graph_tree = rmedge(graph_full, ...
    find(~ismember(graph_full.Edges.Weight, edges_tree)));

%% Step 5: Extract all shortest paths to terminal nodes
tree_edges_cell = cell(length(terminal_nodes), 1);
for i = 1:length(terminal_nodes)
    [~, ~, edgepath] = shortestpath(graph_tree, plantStartingNodes(1), terminal_nodes(i));
    tree_edges_cell{i} = edgepath(:);
end

tree_edges_final = unique(cell2mat(tree_edges_cell));
tree_final = rmedge(graph_tree, ...
    find(~ismember(1:length(graph_tree.Edges.Weight), tree_edges_final)));

%% Step 6: Build final edge list
overallEdges_tree = overallEdges_plant(tree_final.Edges.Weight, :);

%% Step 7: Filter and reindex skeleton points
skel_points_tree = skel_points_plant(ismember(skel_points_plant(:,4), ...
    vertcat(overallEdges_tree{:,1})), :);

for i = 1:size(overallEdges_tree,1)
    nodes = overallEdges_tree{i,1};
    [~, idx_map] = ismember(nodes, skel_points_tree(:,4));
    overallEdges_tree{i,1} = idx_map;
    overallEdges_tree{i,2} = idx_map(1);
    overallEdges_tree{i,3} = idx_map(end);
end

%% Step 8: Reindex starting nodes
[a, plantStartingNodes_tree_] = ismember(plantStartingNodes, skel_points_tree(:,4));
plantStartingNodes_tree = plantStartingNodes_tree_(a);
skel_points_tree(:,4) = 1:size(skel_points_tree,1);

end


function v = normalizeVec(v)
% Normalize a row vector
v = v / norm(v);
end