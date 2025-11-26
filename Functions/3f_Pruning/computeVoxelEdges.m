function [edges_x, edges_y, edges_z] = computeVoxelEdges(ptCloud, voxel_size)
    edges_x = min(ptCloud(:,1)):voxel_size:max(ptCloud(:,1))+voxel_size;
    edges_y = min(ptCloud(:,2)):voxel_size:max(ptCloud(:,2))+voxel_size;
    edges_z = min(ptCloud(:,3)):voxel_size:max(ptCloud(:,3))+voxel_size;
end
