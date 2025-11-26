# MonGraphSeg
# Graph-based Segmentation of Plant Point Clouds for Crop Phenotyping

This repository contains a MATLAB implementation for graph-based panoptic segmentation and phenotypic analysis of 3D single plant point clouds of unbranched moncotoloydenous plants

## Overview

The algorithm processes 3D point cloud data of plants and performs:
- Point cloud preprocessing and skeletonization
- Graph-based structural modeling
- Panoptic segmentation (stem and leaf instances)
- Extraction of phenotypic traits

## Requirements

- MATLAB (tested on R2024a or later)
- Computer Vision Toolbox
- Statistics and Machine Learning Toolbox

## Installation

1. Clone or download this repository
2. Add the main folder to your MATLAB path
3. Ensure all required toolboxes are installed

## Usage

### Basic Usage

1. Open `MonGraphSeg_main.m` in MATLAB
2. Configure the input/output settings:
   ```matlab
   options.data_folder = "path/to/your/pointcloud/data/";
   options.has_ground_truth = false;  % Set to true if ground truth labels available
   ```
3. Adjust algorithm parameters as needed (see Parameter Configuration section)
4. Run the script

### Input Data Format

Point cloud files should be in `.txt` or `.mat` format with the following structure:
- Columns 1-3: X, Y, Z coordinates
- Column options.has_ground_truth (optional): Ground truth labels (if `options.has_ground_truth = true`)

### Parameter Configuration

Key parameters can be adjusted in the `MonGraphSeg_main.m` file:

**Ground Removal:**
- `params.ground_angle_threshold_deg`: Maximum angle (degrees) for ground edge classification (default: 50)

**Overlapping Leaf Splitting:**
- `params.min_cycle_length_overlap`: Minimum cycle length for overlapping leaves detection (default: 150)
- `params.junction_merge_distance`: Distance threshold for merging junction nodes (default: 10)

**Graph Pruning:**
- `params.voxel_size_pruning_mm`: Voxel size for pruning (default: 2 mm)

**Panoptic Model Construction:**
- `params.bezier_interval_mm`: Bézier curve sampling interval (default: 100 mm for maize, 60 mm for sorghum)
- `params.dist_leaf_to_stem_mm`: Threshold for leaf-stem connection (default: 2 mm for maize, 0.5 mm for sorghum)
- `params.stem_leaf_area_considered`: Ratio of leaf length for stem segmentation (default: 1 for maize, 1/3 for sorghum)

**Phenotypic Traits:**
- `params.stem_diameter_sample_mm`: Sampling size for stem diameter estimation (default: 10 mm)

## Pipeline Structure

The processing pipeline consists of the following stages:

### 0. Data Loading
Load 3D point cloud data from specified directory

### 1. Preprocessing
- Outlier removal using `pcdenoise`
- Point cloud centering

### 2. Skeletonization
- Laplacian-based contraction method
- Based on: Cao et al. (2010) "Point cloud skeletons via laplacian based contraction"
- Modified by Annika Tobies, 2025

### 3. Graph Model Construction
- **3a) Initial graph**: Create graph from skeleton points
- **3b) Ground removal**: Detect and remove ground edges
- **3c) Overlapping leaf splitting**: Handle overlapping leaves using cycle detection
- **3d) Leaf-stem cycle removal**: Remove erroneous cycles
- **3e) Panoptic segmentation**: Segment stem and individual leaf instances
- **3f) Pruning**: Remove spurious branches
- **3g) Tip node improvement**: Refine endpoint locations
- **3h) Panoptic model construction**: Build parametric Bézier curve models

### 4. Point Cloud Segmentation
Assign point cloud points to segmented instances

### 5. Phenotypic Trait Extraction
Extract the following traits:
- Plant height
- Number of leaf instances
- Stem diameter
- Leaf length and width
- Leaf inclination angles
- Leaf azimuth angles

### 6. Evaluation (optional)
If ground truth is available, compute evaluation metrics

## Output

The algorithm produces:
- `pheno_traits`: Structure containing phenotypic measurements for each dataset
- `evaluation_matrix`: Performance metrics (if ground truth available)
- Visualization figures (if `options.plot_enabled = true`)

## Project Structure

```
.
├── MonGraphSeg_main.m              # Main processing script
├── Functions/
│   ├── 0_Helpfunctions/           # Utility functions
│   ├── 2_SkelettierungLaplacian/  # Skeletonization functions
│   ├── 3a_Initialgraph/           # Initial graph construction
│   ├── 3b_RemoveGround/           # Ground removal
│   ├── 3c_OverlappingLeaves/      # Overlapping leaf handling
│   ├── 3d_RemoveLeafStemCycles/   # Cycle removal
│   ├── 3e_PanSeg_Graph/           # Graph segmentation
│   ├── 3f_Pruning/                # Pruning operations
│   ├── 3g_TipNodes/               # Tip node improvement
│   ├── 3h_Parametrization/        # Parametric model construction
│   ├── 4_SegmentationPointCloud/  # Point cloud segmentation
│   ├── 5_Phenotyping/             # Phenotypic trait extraction
│   └── Evaluation/                # Evaluation functions
├── THIRD_PARTY_NOTICE
│   ├──LICENSE                     # Licence of  Cao, Junjie, et al. "Point cloud skeletons via laplacian based contraction." *2010 Shape Modeling International Conference*. IEEE, 2010.
│   ├──NOTICE                      # Used Third-Party-Code
└── README.md
└── LICENSE.txt
```

## References

### Skeletonization
- Cao, Junjie, et al. "Point cloud skeletons via laplacian based contraction." *2010 Shape Modeling International Conference*. IEEE, 2010.

### Overlapping Leaf Splitting
- Based on Miao, T., Zhu, C., Xu, T., Yang, T., Li, N., Zhou, Y., & Deng, H. (2021). "Automatic stem-leaf segmentation of maize shoots using three-dimensional point cloud." *Computers and Electronics in Agriculture*, 187, 106310.

## Citation

If you use this code in your research, please cite:
--> will be added after positive review

## License

MIT-License

## Contact

Annika Tobies, atobies@uni-bonn.de

## Acknowledgments
- THIRD_PARTY_NOTICE
