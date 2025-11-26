function panoptic_segmentation_pC = SegmentationPointCloud( ...
    ptCloud_all, panopticModel, blockSize, ...
    ground_existing, skel_points_tree, plantStartingNodes_tree)
% SEGMENTATIONPOINTCLOUD Assigns each point in a point cloud to the closest plant graph segment.
% For each point, returns the nearest plant instance, the distance, and the edge ID (k).
%
% Inputs:
%   ptCloud_all              - [N x 3] point cloud (XYZ only)
%   panopticModel            - cell array of node lists per plant [K x 3] each
%   blockSize                - number of points processed per block
%   ground_existing          - boolean flag, whether to consider ground z-difference
%   skel_points_tree         - full list of skeleton points
%   plantStartingNodes_tree  - list of start node indices (one per plant)
%
% Output:
%   panoptic_segmentation_pC - [N x 3] matrix with columns:
%                               [plant ID, minimum distance, edge ID (k)]

    numInstance = size(panopticModel, 1);

    % --- Build edge lists for each plant
    edges_overall = cell(numInstance, 1);
    for i = 1:numInstance
        nodeCoords = panopticModel{i}(:, 1:3);
        edges_overall{i} = [nodeCoords(1:end-1, :), nodeCoords(2:end, :)];  % [x1 y1 z1 x2 y2 z2]
    end

    pts = ptCloud_all(:, 1:3);
    numPoints = size(pts, 1);
    numPlants = length(edges_overall);
    panoptic_segmentation_pC = zeros(numPoints, 3);  % [plantID, minDist, edgeID]

    % --- Precompute edge vectors and lengths
    edgesPre = cell(numPlants,1);
    ABPre = cell(numPlants,1);
    AB_norm_sqPre = cell(numPlants,1);
    for j = 1:numPlants
        edges = edges_overall{j};
        A = edges(:, 1:3);
        B = edges(:, 4:6);
        AB = B - A;
        AB_norm_sq = sum(AB.^2, 2);
        AB_norm_sq(AB_norm_sq == 0) = eps;  % avoid division by zero

        edgesPre{j} = edges;
        ABPre{j} = AB;
        AB_norm_sqPre{j} = AB_norm_sq;
    end

    % --- Block-wise processing
    for blockStart = 1:blockSize:numPoints
        blockEnd = min(blockStart + blockSize - 1, numPoints);
        blockIdx = blockStart:blockEnd;
        ptsBlock = pts(blockIdx, :);
        blockLen = length(blockIdx);

        distInstance = inf(blockLen, numPlants);
        edgeIDsInstance = zeros(blockLen, numPlants);

        for j = 1:numPlants
            edges = edgesPre{j};
            A = edges(:, 1:3);
            B = edges(:, 4:6);
            AB = ABPre{j};
            AB_norm_sq = AB_norm_sqPre{j};
            numEdges = size(edges, 1);

            % Vectorized distance computation for all edges at once
            % Reshape: ptsBlock [blockLen x 3] -> [blockLen x 1 x 3]
            % A, B, AB: [numEdges x 3] -> [1 x numEdges x 3]
            ptsExp = reshape(ptsBlock, [blockLen, 1, 3]);
            AExp = reshape(A, [1, numEdges, 3]);
            BExp = reshape(B, [1, numEdges, 3]);
            ABExp = reshape(AB, [1, numEdges, 3]);
            AB_norm_sq_exp = reshape(AB_norm_sq, [1, numEdges]);

            % AP: [blockLen x numEdges x 3]
            AP = ptsExp - AExp;
            
            % lambda: [blockLen x numEdges]
            lambda = sum(AP .* ABExp, 3) ./ AB_norm_sq_exp;
            
            % projection: [blockLen x numEdges x 3]
            proj = AExp + lambda .* ABExp;
            
            % distance to projection: [blockLen x numEdges]
            dist = sqrt(sum((ptsExp - proj).^2, 3));
            
            % Correct for points outside segment
            below0 = lambda < 0;
            above1 = lambda > 1;
            
            % Distance to point A for points below segment
            dist_to_A = sqrt(sum((ptsExp - AExp).^2, 3));
            dist(below0) = dist_to_A(below0);
            
            % Distance to point B for points above segment
            dist_to_B = sqrt(sum((ptsExp - BExp).^2, 3));
            dist(above1) = dist_to_B(above1);
            
            % Find minimum distance and corresponding edge for this plant
            [minDist, minEdgeIdx] = min(dist, [], 2);
            
            % Update global minimum across plants
            update_mask = minDist < distInstance(:, j);
            distInstance(update_mask, j) = minDist(update_mask);
            edgeIDsInstance(update_mask, j) = minEdgeIdx(update_mask);
        end

        % --- Optional: add vertical ground distance (Z difference)
        if ground_existing
            groundZ = skel_points_tree(plantStartingNodes_tree, 3);      % [numPlants x 1]
            groundDiff = abs(ptsBlock(:, 3) - groundZ');                 % [blockLen x numPlants]
            distInstance(:,end+1) = groundDiff;  % combine geometrically or logically
            edgeIDsInstance(:,end+1) = 1;
        end

        % --- Final label assignment
        [minVals, minIDs] = min(distInstance, [], 2);

        % Find associated edge index per point
        edgeIDs = zeros(blockLen, 1);
        for ii = 1:blockLen
            edgeIDs(ii) = edgeIDsInstance(ii, minIDs(ii));
        end

        % Store results
        panoptic_segmentation_pC(blockIdx, 1) = minIDs;     % plant ID
        panoptic_segmentation_pC(blockIdx, 2) = minVals;    % minimal distance
        panoptic_segmentation_pC(blockIdx, 3) = edgeIDs;    % edge ID
    end
end
