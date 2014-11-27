init;

NKeypoints = 49;
NModels = 9;
Expressions = {'Angry', 'Disgust', 'Fear', 'Happy', 'Sad', 'Surprise'};

eye1 = [1:5 20:25];
eye2 = [6:10 26:31];
eyes = [eye1 eye2];
nose = 11:19;
mouth = 32:49;
typeidx = eyes;
type = 'eyes';

%Landscape parameters
xrange = linspace(0, 1, 25);
yrange = linspace(0, 0.5, 25);

DGMs = cell(NModels, length(Expressions));
MaxPers = zeros(NModels, length(Expressions));
Landscapes = zeros(NModels*length(Expressions), length(xrange)*length(yrange));
LandscapesColor = zeros(NModels*length(Expressions), 1);
c = [1 0 0; 0 1 0; 0 0 1; 1 1 0; 1 0 1; 0 1 1];


for ii = 1:NModels
    for jj = 1:length(Expressions)
        filename = sprintf('F%.3i/%s/AllDists.mat', ii, Expressions{jj});
        load(filename);
        D = DGeodesics;
        %D = DEuclids;
        N = 0;
        for kk = 1:length(D);
            if D{kk} ~= -1;
                N = N + 1;
            end
        end
        NewD = zeros(N, length(typeidx)^2);
        idx = 1;
        for kk = 1:length(D)
            if D{kk} ~= -1
                thisD = D{kk}(typeidx, typeidx);
                NewD(idx, :) = thisD(:);
                idx = idx + 1;
            end
        end
        D = squareform(pdist(NewD));
        idx = (ii-1)*length(Expressions) + jj;
        subplot(NModels, length(Expressions), idx);
        imagesc(D);
        if (ii == 1)
            title(Expressions{jj});
        end
        set(gca,'YTickLabel',[]);
        set(gca,'XTickLabel',[]);

        if (jj == 1)
            ylabel(sprintf('%i', ii));
        end
        D = D/max(D(:));%Normalize to 1
        I = rca1dm(D, 100);
        DGMs{ii}{jj} = I;
        MaxPers(ii, jj) = max(I(:, 2) - I(:, 1));
        L = getRasterizedLandscape(I, xrange, yrange);
        Landscapes(idx, :) = L(:);
        LandscapesColor(idx) = jj;
    end
end

figure;
boxplot(MaxPers, Expressions);

figure;
[YEigs, Y] = pca(Landscapes);

scatter3(Y(:, 1), Y(:, 2), Y(:, 3), 20, c(LandscapesColor, :));
