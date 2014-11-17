addpath('../toolbox_fast_marching');
addpath('../toolbox_fast_marching/toolbox');
addpath('../toolbox_fast_marching/data');

heart = load('testdata.mat');
NFrames = size(heart.X, 1);
X = heart.X;
Y = heart.Z;
Z = heart.Y;

Ds = {};

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

L1Stress = zeros(NFrames, NFrames);
L2Stress = zeros(NFrames, NFrames);
GHStress = zeros(NFrames, NFrames);
for ii = 1:NFrames
   D1 = Ds{ii}(1:12, 1:12);
   for jj = 1:NFrames
      D2 = Ds{jj}(1:12, 1:12);
      diff = D1 - D2;
%       locs1 = [X(ii, :)' Y(ii, :)' Z(ii, :)'];
%       locs2 = [X(jj, :)' Y(jj, :)' Z(jj, :)'];
%       diff = locs1 - locs2;
      L1Stress(ii, jj) = sum(abs(diff(:)));
      L2Stress(ii, jj) = sum(diff(:).^2);
      GHStress(ii, jj) = max(abs(diff(:)));
   end
end

% for ii = 1:NFrames
%     [vertex, faces] = read_mesh( sprintf('%i.off', ii) );
%     this_stress = stresses(ii, :)';
%     this_stress = this_stress/max(stresses(:));
%     plot_fast_marching_mesh(vertex,faces, this_stress, []);
%     colorbar;
%     caxis([0, 0.8]);
%     shading interp;
%     view(-78, 10);
%     xlim([min(X(:)) - 10, max(X(:)) + 10]);
%     ylim([min(Y(:)) - 10, max(Y(:)) + 10]);
%     zlim([min(Z(:)) - 10, max(Z(:)) + 10]);
%     print('-dpng', '-r100', sprintf('%i.png', ii));
% end