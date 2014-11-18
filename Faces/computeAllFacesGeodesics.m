faces = arrayfun(@(x) {sprintf('F%.3i', x)}, (1:9)');
types = {'Angry', 'Disgust', 'Fear', 'Happy', 'Sad', 'Surprise'};

for ii = 1:length(faces)
    AllXEuclids = cell(1, length(types));
    AllDEuclids = cell(1, length(types));
    AllDGeodesics = cell(1, length(types));
    Alltis = cell(1, length(types));
    Allbcs = cell(1, length(types));
    parfor jj = 1:length(types)
        XEuclids = {};
        DEuclids = {};
        DGeodesics = {};
        tis = {};
        bcs = {};
        foldername = sprintf('%s/%s', faces{ii}, types{jj});
        kk = 0;
        while 1
            filePrefix = sprintf('%s/%.3i', foldername, kk);
            fprintf(1, '%s\n', filePrefix);
            if ~exist(sprintf('%s.off', filePrefix))
                fprintf(1, 'Stopping at %s\n', filePrefix);
                break;
            end
            [XInterp3D, DFinalEuclidean, DFinalGeodesic, ti, bc] = ...
                computeGeodesicsFromTexCoords(filePrefix, 1);
            XEuclids{end+1} = XInterp3D;
            DEuclids{end+1} = DFinalEuclidean;
            DGeodesics{end+1} = DFinalGeodesic;
            tis{end+1} = ti;
            bcs{end+1} = bc;
            kk = kk + 1;
        end
        AllXEuclids{jj} = XEuclids;
        AllDEuclids{jj} = DEuclids;
        AllDGeodesics{jj} = DGeodesics;
        Alltis{jj} = tis;
        Allbcs{jj} = bcs;
    end
    for jj = 1:length(types)
        foldername = sprintf('%s/%s', faces{ii}, types{jj});
        XEuclids = AllXEuclids{jj};
        DEuclids = AllDEuclids{jj};
        DGeodesics = AllDGeodesics{jj};
        tis = Alltis{jj};
        bcs = Allbcs{jj};
        save(sprintf('%s/AllDists.mat', foldername), 'XEuclids', 'DEuclids', 'DGeodesics', 'tis', 'bcs'); 
    end
end