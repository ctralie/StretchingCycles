%TODO: Things to improve teh correctness of the algorithm
%1) Take geodesic boundary for mask instead of drawing lines in 2D
%2) Try to get rid of quantization noise in each mesh

addpath('RealSenseMATLAB');
addpath(genpath('../toolbox_fast_marching'));
addpath(genpath('../ShapeLAB'));

% set path and read in images
N = 705;
fpath = 'Chris\';
ftype = '.png';

[DM,TM,option] = xx_initialize;
output.pred = [];

faceboundingpoly = [20 21 22 27 28 29 38 39 40 41 42 43 32];

for fnum = 0%:N-1
    fprintf(1, 'Doing fnum = %i...\n', fnum);
    rgb = imread(strcat(fpath, 'B-color', num2str(fnum), ftype));
    uv_rgb = uvread(strcat(fpath, 'B-color-uv', num2str(fnum), ftype));
    pc = pcread(strcat(fpath, 'B-cloud', num2str(fnum), ftype));

    %Step 1: Find landmarks in high resolution rgb image
    output = xx_track_detect(DM, TM, rgb, output.pred, option);
    lm = output.pred;
    %Do bilinear interpolation on each landmark to determine location
    %in point cloud
    for kk = 1:size(lm, 1)
        u = lm(kk, 2);      u0 = floor(u);      u1 = ceil(u);
        v = lm(kk, 1);      v0 = floor(v);      v1 = ceil(v);
        utop = (u1-u)*uv_rgb(u0, v0, 1) + (u-u0)*uv_rgb(u1, v0, 1);
        ubottom = (u1-u)*uv_rgb(u0, v1, 1) + (u-u0)*uv_rgb(u1, v1, 1);
        lm(kk, 2) = (v1-v)*ubottom + (v-v0)*utop;
        vtop = (u1-u)*uv_rgb(u0, v0, 2) + (u-u0)*uv_rgb(u1, v0, 2);
        vbottom = (u1-u)*uv_rgb(u0, v1, 2) + (u-u0)*uv_rgb(u1, v1, 2);
        lm(kk, 1) = (v1-v)*vbottom + (v-v0)*vtop;
    end
    lm(:, 1) = lm(:, 1)*size(pc, 1);
    lm(:, 2) = lm(:, 2)*size(pc, 2);
    %Make points on the cheek
    lm(end+1, :) = 0.5*(lm(20, :) + lm(32, :));
    lm(end+1, :) = 0.5*(lm(29, :) + lm(38, :));
    lm = double(lm);
    
    %Step 2: Create a mask as the binary AND of a region enclosed by some
    %of the keypoints and the regions which are not NaNs
    
    %Create the mask by rasterizing a polygon on the 2D grid
    %TODO: Implement a more robust cropping mask with geodesics
    mask = poly2mask(lm(faceboundingpoly, 2), lm(faceboundingpoly, 1), size(pc, 1), size(pc, 2));
    mask = mask & ~isnan(pc(:, :, 3));
    
    %Extract the points within the mask
    pc = bsxfun(@times, pc, single(mask));
    X = pc(:, :, 1);    X = X(:);   X = X(mask(:));
    Y = pc(:, :, 2);    Y = Y(:);   Y = Y(mask(:));
    Z = pc(:, :, 3);    Z = Z(:);   Z = Z(mask(:));
    verts = double([X Y Z]);
    
    %Figure out which triangles are taken over the points by constructing
    %all triangles over the grid and keeping the ones which include
    %points in the mask
    pointIndices = zeros(size(mask));
    pointIndices(mask == 1) = 1:sum(mask(:));
    W = size(mask, 2);
    H = size(mask, 1);
    
    %Tricky code for using matlab to build triangles on grid
    heightrep = 1:H-2;  heightrep = heightrep(:);
    widthrep = (1:W-2)*H;   widthrep = reshape(widthrep, [1 1 length(widthrep)]);
    tris1idx = [1 H+2 H+1];
    tris1idx = bsxfun(@plus, tris1idx, heightrep);
    tris1idx = bsxfun(@plus, tris1idx, widthrep);
    tris1idx = shiftdim(tris1idx, 2);
    tris1idx = reshape(tris1idx, [size(tris1idx, 1)*size(tris1idx, 2), size(tris1idx, 3)]);
    tris2idx = [1 2 H+2];
    tris2idx = bsxfun(@plus, tris2idx, heightrep);
    tris2idx = bsxfun(@plus, tris2idx, widthrep);
    tris2idx = shiftdim(tris2idx, 2);
    tris2idx = reshape(tris2idx, [size(tris2idx, 1)*size(tris2idx, 2), size(tris2idx, 3)]);
    %Keep only the triangles with all 3 points chosen in the vertex mask
    tris = [tris1idx; tris2idx];
    tris = tris(sum(mask(tris), 2) == 3, :);
    %Create a mapping into the new indices of the vertices
    tris = pointIndices(tris);
    
    %Step 3: Write mesh to disk and call meshlab to fill in holes
    %apply Laplacian smoothing in depth and do quadratic edge collapse
    %to downsample
    writeOff('facestemp.off', verts, tris);
    system('meshlabserver -i facestemp.off -s fillholesandsmooth.mlx -o facestemp.off');
    [verts, tris] = read_mesh('facestemp.off');
    shading interp;
    verts = verts';
    tris = tris';
    
    %Step 4: Compute the functional map between this face and the first
    %face mesh and use it to compute the shape difference
    
    %Set up 3D shape descriptors with indicator Gaussians at keypoints
    S.TRIV = tris;
    S.X = verts(:, 1);
    S.Y = verts(:, 2);
    S.Z = verts(:, 3);
    %TODO: Finish setting up indicators
    disp('Calculating Laplacian Basis...');
    [W, A] = mshlp_matrix(S, struct('dtype', 'cotangent'));
    [S.evecs, S.evals, S.areas, S.W] = calcLaplacianBasis(S, size(verts, 1));    
    disp('Finished calculating Laplacian Basis');
end