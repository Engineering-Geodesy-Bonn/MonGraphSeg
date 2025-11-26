function branching_point = detectFirstBranch(graph_A, overallEdges, updated_skeleton_points, max_point, params)
% DETECTFIRSTBRANCH - Identifies the all branching point in a plant skeleton, that fullfill the verticallity criteria.
%
% Syntax:
%   branching_point = detectFirstBranch(graph_A, overallEdges, updated_skeleton_points, max_point, A_parameter)
%
% Inputs:
%   graph_A               - MATLAB graph object representing the skeleton.
%                            * graph_A.Nodes.Coordinates contains 3D positions of nodes.
%   overallEdges          - Cell array of edges, each row contains:
%                            * {edgeID, node1, node2}
%   updated_skeleton_points - Nx4 matrix where:
%                            * Columns 1-3: 3D coordinates
%                            * Column 4: Node ID in graph_A
%   max_point             - Node ID of the plant apex in graph_A.
%   A_parameter           - Struct with field:
%                            * angle_threshold_ground (degrees, e.g., 45)
%
% Outputs:
%   branching_point       - Vector of unique node IDs where the first branch is detected.
%
% Description:
%   This function analyzes a plant skeleton graph to determine the first branching node.
%   The method follows these steps:
%     1. Extract all nodes associated with the skeleton edges.
%     2. Compute the shortest path from each skeleton node to the plant apex (max_point).
%     3. Check if the branching occurs within an angle threshold relative to the vertical direction.
%     4. Return unique branching points based on spatial characteristics.
%
% Example:
%   branching_point = detectFirstBranch(G, edges, skeleton_pts, apex_id, struct('angle_threshold_ground', 45));

    % Extract unique node IDs from overallEdges
    nodes_graphB = unique(cell2mat(overallEdges(:, 2:3)));

    % Initialize matrix to store detected branching information
    plant_first_branch = zeros(size(updated_skeleton_points, 1), 2);
    plant_first_branch(:,1) = updated_skeleton_points(:,4); % Store current node IDs

    % Iterate through skeleton nodes to detect branching points
    for i = 1:size(updated_skeleton_points, 1)
       
        % Compute shortest path from current node to plant apex
        path_i = shortestpath(graph_A, i, max_point);

        % Get coordinates for the current node and path nodes
        node_xyz = graph_A.Nodes.Coordinates(i, 1:3);
        path_B_xyz = graph_A.Nodes.Coordinates(path_i, 1:3);

        % Compute directional vectors along the path
        if size(path_B_xyz, 1) > 1
            vectors = path_B_xyz(2:end, :) - node_xyz;
            angles = acosd(vectors(:,3) ./ vecnorm(vectors, 2, 2));

            % Check if all vectors remain within the angle threshold
            if all(angles < params.ground_angle_threshold_deg)
                % Identify nodes that belong to Graph B
                path_i_graphB_mask = ismember(path_i, nodes_graphB);
                nodes_graphB_filtered = path_i(path_i_graphB_mask);

                % Determine first valid branch node
                if path_i_graphB_mask(1)
                    if nodes_graphB_filtered>1
                    plant_first_branch(i,2) = nodes_graphB_filtered(2);
                    end
                else
                    plant_first_branch(i,2) = nodes_graphB_filtered(1);
                end
            end
        end
    end

    % Extract unique branching points, excluding zero entries
    branching_point = unique(plant_first_branch(:,2));
    branching_point(branching_point == 0) = [];

end
