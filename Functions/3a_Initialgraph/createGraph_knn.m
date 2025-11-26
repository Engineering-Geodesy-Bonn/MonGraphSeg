function [edges] = createGraph_knn(points_skel)
% This function defines the preliminary edges of a graph using a
% k-nearest neighbor (k-NN) calculation.
% INPUT: points_skeleton (xyz coordinates of the skeleton)
% OUTPUT: edges (for each edge: start node, end node, distance), start id is always <= end  

    % Set the number of neighbors per point
    k = 3;  
    
    % Find the k nearest neighbors for each point
    [idx, distances] = knnsearch(points_skel, points_skel, 'K', k+1); 
    idx = idx(:, 2:end);        % Remove the point itself
    distances = distances(:, 2:end); % Remove the distance to itself

    % Prepare arrays for edge creation
    start_points = (ones(size(points_skel,1), k) .* (1:(size(points_skel,1)))');
    start_points = reshape(start_points.', [], 1);
    end_points = reshape(idx.', [], 1);
    edge_distances = reshape(distances.', [], 1);

    % Combine start and end points, sort them so that start <= end,
    % and remove duplicate edges
    edges = unique([sort([start_points, end_points], 2), edge_distances], 'rows'); 
end

