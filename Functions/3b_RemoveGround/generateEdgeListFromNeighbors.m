function edges_list = generateEdgeListFromNeighbors(updated_neighbors) 
%GENERATEEDGELISTFROMNEIGHBORS Converts neighbor matrix to a sorted, unique edge list 

% % Input: 
    % updated_neighbors - NxK matrix where each row contains node neighbors 
% % Output: 
    % edges_list - Mx2 array of unique, sorted edges 

    num_neighbors = size(updated_neighbors, 2); 
    num_nodes = size(updated_neighbors, 1); 
    edges_list = zeros((num_neighbors - 1) * num_nodes, 2); 
    for i = 1:num_neighbors - 1 
        idx_start = (i - 1) * num_nodes + 1; 
        idx_end = i * num_nodes; 
        edges_list(idx_start:idx_end, :)= [updated_neighbors(:, 1), updated_neighbors(:, i + 1)]; 
    end 
    % Remove invalid edges and duplicates 
    edges_list = sort(edges_list, 2); 
    edges_list(edges_list(:,1) == 0, :) = []; 
    edges_list = unique(edges_list, 'rows'); 
end