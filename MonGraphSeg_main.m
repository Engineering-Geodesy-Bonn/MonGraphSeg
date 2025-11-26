%% Graph-based Segmentation of Plant Point Clouds for Crop Phenotyping

clc; close all; clear;

%% General Visualization Settings
set(0, ...
    'DefaultTextFontSize', 20, ...
    'DefaultAxesFontSize', 18, ...
    'DefaultAxesTitleFontWeight', 'normal', ...
    'DefaultAxesTitleFontSizeMultiplier', 1.3, ...
    'defaultAxesTickLabelInterpreter','latex', ...
    'defaultLegendInterpreter','latex', ...
    'defaulttextInterpreter','latex', ...
    'defaultTextFontName','Computer Modern');

%% Input / Output Settings
options.plot_enabled = true;                      % Enable/disable plotting
options.data_folder = "D:\Data_Phaenotypisierung\PW_LT_Sorghum/";   % Path to point cloud dataset
options.has_ground_truth = true;                  % Ground truth available?
options.gt_column_index = 4;                      % Column index for ground truth labels

%% Algorithm Parameters

% --- Ground Removal (Section 3b)
params.ground_angle_threshold_deg = 50;            % Max angle (in degrees) w.r.t. z-axis to classify ground edges

% --- Overlapping Leaf Splitting (Section 3c)
params.min_cycle_length_overlap = 150;             % Minimum cycle length to detect overlapping leaves
params.junction_merge_distance = 10;               % Distance to merge nearby junction nodes around the detected one

% --- Graph Pruning (Section 3f)
params.voxel_size_pruning_mm = 2;                  % Voxel size [mm] for pruning based on connected components

% --- Panoptic Model Construction (Section 3h)
params.bezier_interval_mm = 60;                   % Interval size for Bezier curve sampling [mm], 100 Maize, 60 Sorghum
params.dist_leaf_to_stem_mm = 0.5;                   % Threshold for De-Casteljau connection of leaf and stem, 2 Maize, 0.5 Sorghum
params.stem_leaf_area_considered = 1/3;            % Ratio of leaf length considered for transition to stem, 1 Maize, 1/3 Sorghum

% --- Phenotypic Traits (Section 5)
params.stem_diameter_sample_mm = 10;               % Diameter sampling size for stem estimation [mm]

% --- Preprocessing Parameters (Section 1)
params.pcdenoise_threshold = 3;                    % Threshold for outlier removal
params.pcdenoise_neighbors = 30;                   % Number of neighbors for denoising
params.max_points_segmentation = 50000;            % Maximum points per segmentation batch

%% Setup Environment and Dataset

% Add function and data folders to MATLAB path
addpath(options.data_folder);
addpath(genpath("Functions"));

% Load and filter dataset files (ignore empty entries and folders)
dataset_list = dir(options.data_folder);
valid_datasets = dataset_list([dataset_list.bytes] > 0 & ~[dataset_list.isdir]);
clear dataset_list

fprintf('Algorithm started...\n');
fprintf('#datasets found: %d\n', numel(valid_datasets));

% Check if datasets are available
if isempty(valid_datasets)
    error('No valid datasets found in %s', options.data_folder);
end

% Initialize evaluation matrix
evaluation_matrix = zeros(numel(valid_datasets), 6);

%% Processing of data sets
for index_dataset = 1:numel(valid_datasets)
    close all;  % Close all open figures
    fprintf('- Processing dataset %d/%d: %s\n', index_dataset, numel(valid_datasets), valid_datasets(index_dataset).name);


    %% 0) Load data
    ptCloud_all = load(options.data_folder + valid_datasets(index_dataset).name);  % Load point cloud
    fprintf('### Point cloud loaded\n')

    %% 1) Preprocessing
    % Denoise point cloud (remove outliers)
    [ptCloud1, InlierIndices, ~] = pcdenoise(pointCloud(ptCloud_all(:,1:3)), ...
        "Threshold", params.pcdenoise_threshold, 'NumNeighbors', params.pcdenoise_neighbors);

    % Center the point cloud around the origin
    meanPC = mean(ptCloud1.Location);
    ptCloud = ptCloud1.Location - meanPC;

    % Keep additional information (e.g., labels) for inlier points
    ptCloud_all = [ptCloud, ptCloud_all(InlierIndices,4:end)];

    % Plot the preprocessed point cloud
    plotPC(ptCloud_all, options)
    clear ptCloud1 InlierIndices ptCloud meanPC
    fprintf('### Point cloud preprocessed\n')


    %% 2) Skeletonization
    % Cao, Junjie, et al. "Point cloud skeletons via laplacian based contraction." 2010 Shape Modeling International Conference. IEEE, 2010.
    % Copyright 2025 [Annika Tobies]
    %  This file includes modifications of code from the cloudcontr project
    %  (https://github.com/taiya/cloudcontr), licensed under the Apache License 2.0.
    % Modified by: Annika Tobies
    % Data: 2025
    % Licensed under the Apache License, Version 2.0 (the "License");
    %  you may not use this file except in compliance with the License.
    %  You may obtain a copy of the License at:
    % http://www.apache.org/licenses/LICENSE-2.0

    [points_skel] = Skeleton_function(ptCloud_all, options);

    %% 3) Graph model
    % 3a) Initial graph
    [overallEdges,updated_skeleton_points,updated_neighbors] = computeInitialGraph(points_skel, options);
    clear points_skel

    % 3b) Removal of ground edges
    [overallEdges_plant, skel_points_plant,plantStartingNodes,ground_existing] = extractPlantStructure(updated_neighbors, updated_skeleton_points, overallEdges, params);
    visualizeGroundRemoval(overallEdges_plant, overallEdges, skel_points_plant, updated_skeleton_points, options);
    clear updated_skeleton_points updated_neighbors overallEdges
    fprintf('### Ground nodes removed\n')

    % 3c) Splitting of overlapping leaves
    % based on: Miao, T., Zhu, C., Xu, T., Yang, T., Li, N., Zhou, Y., & Deng, H. (2021). "Automatic stem-leaf segmentation of maize shoots using three-dimensional point cloud."
    [skel_points_plant, overallEdges_plant] = splitOverlappingLeaves(skel_points_plant, overallEdges_plant, plantStartingNodes, params);

    % 3d) Remove leaf-stem-cycles
    [overallEdges_tree, skel_points_tree, plantStartingNodes_tree] = rm_leaf_stem_cycles(overallEdges_plant, skel_points_plant, plantStartingNodes);
    plotTreeAndRemovedEdges(skel_points_plant, skel_points_tree, overallEdges_plant, overallEdges_tree, options);
    fprintf('### Leaf-Stem-Cycle removed\n')
    clear skel_points_plant plantStartingNodes overallEdges_plant

    % 3e) Panoptic segmentation of the graph model
    % Segmentation of the stem
    [overallEdges_tree,edges_of_Stem,path_stem] = extractStemPath(overallEdges_tree, skel_points_tree, plantStartingNodes_tree);
    % Segmentation of the leaves
    overallEdges_tree = segmentLeaves(overallEdges_tree, path_stem, edges_of_Stem);
    plotSegmentedGraph(overallEdges_tree, skel_points_tree, "Initial graph panoptic segmented", options)
    clear edges_of_Stem
    fprintf('### Initial segmentation computed\n')

    % 3f) Pruning
    % Remove spurious branches at the leaves
    overallEdges_tree_concluded = removeSpuriousLeafBranches(overallEdges_tree, path_stem, skel_points_tree);
    clear overallEdges_tree
    % Remove spurious branches at the stem
    % Assign point cloud to closest graph instance
    edges_panoptic = cellfun(@(idx) skel_points_tree(idx, 1:3), overallEdges_tree_concluded(:,1), 'UniformOutput', false);
    pointLabels = SegmentationPointCloud(ptCloud_all, edges_panoptic, params.max_points_segmentation, ground_existing, skel_points_tree, plantStartingNodes_tree(1));
    clear edges_panoptic
    [spurious_instances,edges_x, edges_y, edges_z] = detectSpuriousInstances_stem(ptCloud_all, pointLabels(:,1), overallEdges_tree_concluded, skel_points_tree, params, ground_existing);
    % Consider ground connection
    spurious_instance_ground = removeSpuriousInstances(ptCloud_all, pointLabels(:,1), overallEdges_tree_concluded, skel_points_tree, edges_x, edges_y, edges_z, params, ground_existing, false);
    clear edges_x edges_y edges_z pointLabels
    spurious_instance_all = (spurious_instances+spurious_instance_ground)>0;
    clear spurious_instances spurious_instance_ground
    overallEdges_tree_pruned = overallEdges_tree_concluded(~spurious_instance_all,:);
    clear overallEdges_tree_concluded spurious_instance_all

    % Detect and remove spurious stem tip
    overallEdges_tree_pruned = detectAndRemoveSpuriousStemTip(overallEdges_tree_pruned, ptCloud_all, skel_points_tree, plantStartingNodes_tree, ground_existing, params);

    % Final panoptic segmentation of graph
    [overallEdges_tree_panSeg, plantStartingNodes_tree] = correct_stem_leaf_classification(overallEdges_tree_pruned, skel_points_tree, params);
    plotSegmentedGraph(overallEdges_tree_panSeg, skel_points_tree, "Final pruned and segmented graph", options)
    clear overallEdges_tree_pruned path_stem
    fprintf('### Pruning finished\n')


    % 3g) Improvement of tip nodes
    % Refine leaf and stem tip positions based on actual point cloud data
    edges_panoptic = cellfun(@(idx) skel_points_tree(idx, 1:3), overallEdges_tree_panSeg(:,1),'UniformOutput', false);
    pointLabels = SegmentationPointCloud(ptCloud_all, edges_panoptic, params.max_points_segmentation, ground_existing, skel_points_tree, plantStartingNodes_tree(1));
    clear edges_panoptic
    [overallEdges_tree_panSeg_tip, skel_points_final] = improvement_tipNode(overallEdges_tree_panSeg, skel_points_tree, ptCloud_all, pointLabels(:,1), pointLabels(:,3));
    clear pointLabels
    plotImprovedTipNodes(overallEdges_tree_panSeg, skel_points_tree, overallEdges_tree_panSeg_tip, skel_points_final, options)
    clear overallEdges_tree_panSeg skel_points_tree

    % 3h) Build panoptic model
    % Create parametric Bezier curve representation for each instance
    panopticModel = buildPanopticModel(overallEdges_tree_panSeg_tip, skel_points_final, params);
    clear overallEdges_tree_panSeg_tip
    plotPanopticModel(panopticModel, options);
    fprintf('### Panoptic model built\n')

    %% 4) Panoptic segmentation Point Cloud
    % Assign each point cloud point to nearest panoptic instance
    panoptic_segmentation_pC = SegmentationPointCloud(ptCloud_all, panopticModel, params.max_points_segmentation, ground_existing, skel_points_final, plantStartingNodes_tree);
    % Refine panoptic model based on actual point assignments
    panopticModel = cutPanopticModel(panopticModel, panoptic_segmentation_pC);
    plotPanSegPointCloud(ptCloud_all, panoptic_segmentation_pC, panopticModel, options)
    fprintf('### Panoptic segmentation of point cloud\n')

    %% 5) Phenotypic Trait Extraction
    % Extract plant-level and organ-level phenotypic parameters

    % Plant height (distance from ground to highest point)
    pheno_traits.plant_height{index_dataset,1} = computePlantHeight(panopticModel, ptCloud_all, panoptic_segmentation_pC, ground_existing);

    % Number of instances (stem + leaves)
    pheno_traits.numberInstances{index_dataset,1} = reportInstanceSummary(panopticModel, ground_existing);

    % Stem diameter at multiple heights
    % Includes:  fit_ellipse.m
    % Original function by Ohad Gal
    % Source:
    %   Ohad Gal, "fit_ellipse", MATLAB Central File Exchange
    %   https://www.mathworks.com/matlabcentral/fileexchange/3215-fit_ellipse
    pheno_traits.diameter_mm{index_dataset,1} = computeStemDiameter(panopticModel, panoptic_segmentation_pC, ptCloud_all, params.stem_diameter_sample_mm);

    % Leaf area (optional, computationally expensive)
    % Staußberg, Lina et al. Automated Surface Area Estimation of Plants based on 3D Point Clouds (2021)
    pheno_traits.leaf_area{index_dataset,1} = estimate_leaf_areas(ptCloud_all, panoptic_segmentation_pC, panopticModel);

    % Leaf length and width for each leaf instance
    pheno_traits.leaf_length_width{index_dataset,1}= estimate_leaf_length_width(panopticModel, panoptic_segmentation_pC);

    % Leaf inclination angles (angle from horizontal plane)
    pheno_traits.inclination{index_dataset,1}= computeLeafInclinations(panopticModel);

    % Azimuth angles (orientation in horizontal plane)
    pheno_traits.azimuth_angle{index_dataset,1} = estimate_leaf_azimuth_angles(panopticModel);
    fprintf('### Computation of phenotypic traits finished\n')

    %% 6) Evaluation
    if options.has_ground_truth
        % Convert model to leaf-tip representation for fair comparison
        panopticModel_lt = panopticModel2LeafTip(panopticModel);
        panoptic_segmentation_pC_lT = SegmentationPointCloud(ptCloud_all, panopticModel_lt, params.max_points_segmentation, ground_existing, skel_points_final, plantStartingNodes_tree);
        plotPanopticEvaluation(panopticModel_lt, ptCloud_all, panoptic_segmentation_pC_lT, options)
        clear panopticModel_lt

        % Extract ground truth and predicted labels
        gt_labels = ptCloud_all(:, options.gt_column_index);
        pred_labels = panoptic_segmentation_pC_lT(:,1);
        clear panoptic_segmentation_pC_lT

        % Compute evaluation metrics (PQ, SQ, RQ, etc.)
        evaluation_matrix(index_dataset,:)  = evaluate_panoptic_segmentation(gt_labels, pred_labels);
        disp(evaluation_matrix(index_dataset,:))
        clear gt_labels pred_labels
    end

    % Free memory for next dataset iteration
    clear ptCloud_all panoptic_segmentation_pC panopticModel ground_existing skel_points_final plantStartingNodes_tree
end

fprintf('\nProcessing completed for all datasets.\n');