function [cpts, t, initWL, WC, sl] = contraction_by_mesh_laplacian(P, options, f, A_options)
% contraction_by_mesh_laplacian: Point cloud contraction using mesh Laplacian
% Based on "Skeleton Extraction by Mesh Contraction" (2008)
%
% Inputs:
%   P.pts         - Points of the mesh
%   P.faces       - Faces of the mesh
%   P.npts        - Number of points
%   P.k_knn       - Number of nearest neighbors for rings
%   P.rings       - 1-ring neighbors
%   options       - Settings structure
%   options.WL    - Initial contraction weight
%   options.WC    - Initial attraction weight
%   options.sl    - Scaling factor for WL per iteration
%   options.tc    - Termination condition (area ratio threshold)
%   options.iterate_time - Max iteration steps
%
% Outputs:
%   cpts          - Contracted points
%   t             - Final iteration number
%   initWL        - Initial Laplacian constraint weight
%   WC            - Initial position constraint weight
%   sl            - Scaling factor for WL
%
% Authors: deepfish, jjcao
% Modified: 2009-2010

if nargin < 1
    % Demo mode with test data (not used in production)
    P.filename = '../data/simplejoint_v4770.off'; 
    options.USING_POINT_RING = GS.USING_POINT_RING;
    options.iterate_time = 10;
    
    [P.pts, P.faces] = read_mesh(P.filename);
    P.npts = size(P.pts, 1);
    P.pts = GS.normalize(P.pts);
    [P.bbox, P.diameter] = GS.compute_bbox(P.pts);
    P.k_knn = GS.compute_k_knn(P.npts);
    
    atria = nn_prepare(P.pts);
    [P.knn_idx, P.knn_dist] = nn_search(P.pts, atria, P.pts, P.k_knn);
    P.rings = compute_point_point_ring(P.pts, P.k_knn, P.knn_idx);
end

%% Settings
RING_SIZE_TYPE = 1; % 1=min, 2=mean, 3=max
Laplace_type = 'conformal'; % Options: 'conformal', 'combinatorial', 'spring', 'mvc'

SHOW_CONTRACTION_PROGRESS = A_options.plot_enabled;

tc = getoptions(options, 'tc', GS.CONTRACT_TERMINATION_CONDITION);
iterate_time = getoptions(options, 'iterate_time', GS.MAX_CONTRACT_NUM);

initWL = getoptions(options, 'WL', GS.compute_init_laplacian_constraint_weight(P, Laplace_type));
sl = getoptions(options, 'sl', GS.LAPLACIAN_CONSTRAINT_SCALE);

if strcmp(Laplace_type, 'mvc')
    WC = getoptions(options, 'WC', 1) * 10;
else
    WC = getoptions(options, 'WC', 1);
end

WH = ones(P.npts, 1) * WC;
WL = initWL;

%% Initialization
t = 1;

if options.USING_POINT_RING
    L = -compute_point_laplacian(P.pts, Laplace_type, P.rings, options);
else
    L = -compute_mesh_laplacian(P.pts, P.faces, Laplace_type, options);
end

A = [L .* WL; sparse(1:P.npts, 1:P.npts, WH)];
b = [zeros(P.npts, 3); sparse(1:P.npts, 1:P.npts, WH) * P.pts];
cpts = (A' * A) \ (A' * b);

if SHOW_CONTRACTION_PROGRESS
    figure(f);
    subplot(2,2,[1,3]);
    movegui('northeast');
    axis off; axis equal; hold on; set(gcf, 'Color', 'white');
    view(-90,0);
    addAxis_Local()
    h1 = scatter3(P.pts(:,1), P.pts(:,2), P.pts(:,3), 10, 'b', 'filled');
    h2 = scatter3(cpts(:,1), cpts(:,2), cpts(:,3), 10, 'r', 'filled');
    title(['Iterate ', num2str(t), ' time(s)']);
end

if options.USING_POINT_RING
    sizes = GS.one_ring_size(P.pts, P.rings, RING_SIZE_TYPE);
    size_new = GS.one_ring_size(cpts, P.rings, RING_SIZE_TYPE);
    a(t) = sum(size_new) / sum(sizes);
else
    ratio_new = area_ratio_1_face_ring(P.pts, cpts, P.faces, P.frings);
    a(t) = mean(ratio_new);
end

%% Iteration
while t < iterate_time
    if options.USING_POINT_RING
        L = -compute_point_laplacian(cpts, Laplace_type, P.rings, options);
    else
        L = -compute_mesh_laplacian(cpts, P.faces, Laplace_type, options);
    end
    
    WL = sl * WL;
    WL = min(WL, GS.MAX_LAPLACIAN_CONSTRAINT_WEIGHT);

    if options.USING_POINT_RING
        if strcmp(Laplace_type, 'mvc')
            WH = WC .* (sizes ./ size_new) * 10;
        else
            WH = WC .* (sizes ./ size_new);
        end
    else
        WH = WC * (ratio_new .^ (-0.5));
    end
    
    WH(WH > GS.MAX_POSITION_CONSTRAINT_WEIGHT) = GS.MAX_POSITION_CONSTRAINT_WEIGHT;

    A = real([WL * L; sparse(1:P.npts, 1:P.npts, WH)]);
    b(P.npts+1:end, :) = sparse(1:P.npts, 1:P.npts, WH) * cpts;
    tmp = (A' * A) \ (A' * b);
    
    if options.USING_POINT_RING
        size_new = GS.one_ring_size(tmp, P.rings, RING_SIZE_TYPE);
        a(end+1) = sum(size_new) / sum(sizes);
    else
        ratio = ratio_new;
        ratio_new = area_ratio_1_face_ring(P.pts, tmp, P.faces, P.frings);
        a(end+1) = mean(ratio_new);
    end
    
    tmpbox = GS.compute_bbox(tmp);
    if any((tmpbox(4:6) - tmpbox(1:3)) > (P.bbox(4:6) - P.bbox(1:3)) * 1.2)
        break;
    end
    
    if a(t) - a(end) < tc || isnan(a(end))
        break;
    else
        cpts = tmp;
    end
    
    t = t + 1;
    
    if SHOW_CONTRACTION_PROGRESS
        delete(h1); delete(h2);
        h1 = scatter3(P.pts(:,1), P.pts(:,2), P.pts(:,3), 10, WH, 'filled');
        h2 = scatter3(cpts(:,1), cpts(:,2), cpts(:,3), 10, ones(P.npts,1)*WL, 'filled');
        title(['Iterate ', num2str(t), ' time(s)']);
        drawnow;
    end
end
clear tmp;

%% Final Visualization
if SHOW_CONTRACTION_PROGRESS
    figure(f);
    subplot(2,2,2);
    plot(1:length(a), a);
    xlabel('Iteration times');
    ylabel('Ratio of original and current volume');
end

end
