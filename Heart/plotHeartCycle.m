addpath('../toolbox_fast_marching');
addpath('../toolbox_fast_marching/toolbox');
addpath('../toolbox_fast_marching/data');

heart = load('testdata.mat');
NFrames = size(heart.X, 1);
X = heart.X;
Y = heart.Z;
Z = heart.Y;

for ii = 1:NFrames
    [vertex, faces] = read_mesh( sprintf('%i.off', ii) );
    D = zeros(size(vertex, 2), size(vertex, 2));
    for jj = 1:size(vertex, 2)
       D(jj, :) = perform_fast_marching_mesh(vertex, faces, jj);
    end
    Ds{ii} = D;
    ii
end

%Compute stresses with respect to first heart
stresses = zeros(NFrames, size(vertex, 2));
D1 = Ds{1};
for ii = 1:NFrames
    D2 = zeros(size(D1));
    D2(1:size(Ds{ii}, 1), 1:size(Ds{ii}, 2)) = Ds{ii};    
    stresses(ii, :) = log(sum((D1 - D2).^2, 2));
end

cycle = [1	2	4	5	6	7	8	11	12	13	14	15	16	17];
D17 = load('DHeartStresses.mat');
[Y, eigs] = cmdscale(D17.D);

for ii = 1:length(cycle)    
    clf;
    [vertex, faces] = read_mesh( sprintf('%i.off', cycle(ii)) );
    this_stress = stresses(cycle(ii), :)';
    this_stress = this_stress/max(GHStress(:));
    this_stress = this_stress(1:size(vertex, 2));
    plot_fast_marching_mesh(vertex,faces, this_stress, []);
    caxis([0, 1]);
    %shading interp;
    view(-3, 36);
    xlim([min(X(:)), max(X(:))]);
    ylim([-50 50]);
    zlim([min(Z(:)/2), max(Z(:))]);
    print('-dpng', '-r100', 'heartImage.png');
    print('-dpng', '-r40', sprintf('%i.png', cycle(ii)));
    system(sprintf('convert -trim %i.png %i.png', cycle(ii), cycle(ii)));
    
    clf;
    numtext = {};
    for kk = 1:size(Y, 1)
       numtext{end+1} = sprintf('%i', kk); 
    end
    scatter(Y(:, 1), Y(:, 2), 50, 'b', 'fill');
    hold on;
    text(Y(:, 1) + 30, Y(:, 2) + 15, numtext);
    plot([Y(cycle, 1); Y(cycle(1), 1)], [Y(cycle, 2); Y(cycle(1), 2)]);
    scatter(Y(cycle(ii), 1), Y(cycle(ii), 2), 50, 'r', 'fill');
    xlabel(sprintf('First Principal Component: %.3g%s', 100*eigs(1)/sum(abs(eigs)), '%') );
    ylabel(sprintf('Second Principal Component: %.3g%s', 100*eigs(2)/sum(abs(eigs)), '%') );
    title(sprintf('Cycle Frame %i, Video Frame %i', ii, cycle(ii)));
    axis equal;axis square;
    
    print('-dpng', '-r100', 'cycleImage.png');
    system('convert -trim cycleImage.png cycleImage.png');
    system(sprintf('convert heartImage.png cycleImage.png +append heartcycle%i.png', ii));
end

%system('for a in *.png; do convert -trim "$a" "$a"; done');

