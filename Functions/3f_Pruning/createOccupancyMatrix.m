function occ_matrix = createOccupancyMatrix(points, edges_x, edges_y, edges_z)
% Discretizes points into a 3D occupancy grid


pc_idx_raster = [discretize(points(:,1) ,edges_x) discretize(points(:,2) ,edges_y) discretize(points(:,3) ,edges_z)];
linear_indices = sub2ind([length(edges_x), length(edges_y), length(edges_z)], ...
    pc_idx_raster(:,1), pc_idx_raster(:,2), pc_idx_raster(:,3));

occ_matrix = accumarray(linear_indices, 1, [length(edges_x) * length(edges_y) * length(edges_z), 1]);
occ_matrix = reshape(occ_matrix, [length(edges_x), length(edges_y), length(edges_z)]) > 0;



end
