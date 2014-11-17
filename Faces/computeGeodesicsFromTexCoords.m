function [XInterp3D, DFinalEuclidean, DFinalGeodesic, ti, bc] = computeGeodesicsFromTexCoords(filePrefix, saveImage)
    if nargin < 2
        saveImage = 0;
    end
    addpath(genpath('../toolbox_fast_marching'));

    TCInfo = load(sprintf('%sTexCoords.mat', filePrefix));
    TCInfo.faces = double(TCInfo.faces);

    [I, dims] = GetFaceKeypoints(sprintf('%s.jpg', filePrefix));
    %Normalize to the range [0, 1]
    I(:, 1) = I(:, 1)/dims(1);
    I(:, 2) = I(:, 2)/dims(2);
    %Swap x and y to be consistent with texture coordinate layout
    ITemp = zeros(size(I));
    ITemp(:, 1) = I(:, 2);
    ITemp(:, 2) = I(:, 1);
    I = ITemp;

    %Get triangle indices and barycentric coordinates
    [ti, bc] = tsearchn(TCInfo.texCoords, TCInfo.faces, I);
    %Figure out which vertices need fast marching
    indices = 1:size(TCInfo.texCoords, 1);
    verts = TCInfo.faces(ti, :);
    indices = unique(indices(verts(:)));
    indexPointers = zeros(size(TCInfo.texCoords, 1), 1);
    indexPointers(indices) = 1:length(indices);

    %Load in 3D mesh
    [vertex, faces] = read_mesh(sprintf('%s.off', filePrefix));

    %Perform Euclidean interpolation for all involved triangles
    XInterp3D = zeros(length(ti), 3);
    for ii = 1:length(ti)
        vertsi = verts(ii, :);
        XInterp3D(ii, :) = vertex(:, vertsi)*bc(ii, :)';
    end

    %Report the Euclidean distances in matrix form
    DFinalEuclidean = squareform(pdist(XInterp3D));
    
    if saveImage
        %Plot the result of Euclidean interpolation
        clf;
        plot_mesh(vertex, faces);
        shading interp;
        hold on;
        scatter3(XInterp3D(:, 1), XInterp3D(:, 2), XInterp3D(:, 3), 20, 'r', 'fill');
        % text(XInterp3D(:, 1), XInterp3D(:, 2), XInterp3D(:, 3)+2, keypointlabels)
        title(filePrefix);
        print('-dpng', '-r100', sprintf('%sKeypoints.png', filePrefix));
    end

    %Perform geodesic interpolation for all involved triangles
    %First do fast marching
    D = zeros(length(indices), length(indices));
    for ii = 1:length(indices)
        thisD = perform_fast_marching_mesh(vertex, faces, indices(ii));
        D(ii, :) = thisD(indices);
    end

    %Now do geodesic interpolation
    DFinalGeodesic = zeros(length(ti), length(ti));
    for ii = 1:length(ti)
        vertsi = indexPointers(verts(ii, :));
        for jj = 1:length(ti)
            vertsj = indexPointers(verts(jj, :));
            %Equations 6.1 and 6.2 in my document
            Dij = zeros(3, 3);
            for kk = 1:3
                Dij(kk, :) = D(vertsi, vertsj(kk));
            end
            DFinalGeodesic(ii, jj) = bc(jj, :)*Dij*bc(ii, :)';
        end
    end
    DFinalGeodesic(1:length(ti)+1:end) = 0;
    DFinalGeodesic = 0.5*DFinalGeodesic + 0.5*DFinalGeodesic';
end