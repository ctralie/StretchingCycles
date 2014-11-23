%
% Sparse Modeling of Intrinsic Correspondences. Computer Graphics Forum '13
% 
addpath(genpath('../ShapeLAB'));

%% Load shapes and parts
s = {};
s{1} = loadShape('1.off');
s{1}.parts = zeros(length(s{1}.X), 1);
s{1}.parts(1:12) = 1;

for ii = 2:17
    s{ii} = loadShape(sprintf('%i.off', ii));
    s{ii}.parts = s{1}.parts;
end

nV = 20; %num eigenfunctions
numFeatureSamples = 100;

for k = 1:length(s)
    s{k}.funcs = {};
    [s{k}.evecs, s{k}.evals, s{k}.areas, s{k}.W] = calcLaplacianBasis(s{k}, nV);
    s{k}.basis = sqrt(s{k}.areas) * s{k}.evecs;
    
    indF = s{k}.parts; 
    s{k}.funcs = {s{k}.funcs{:}, indF};
end  

Cs = cell(1, length(s));
Ds = cell(1, length(s));
for kk = [1:11, 13:length(s)]
    kk
    [C O] = calcCFromFuncsAndStructure(s{1}, s{kk}, s{1}.funcs, s{kk}.funcs, 'basis1', s{1}.basis, 'basis2', s{kk}.basis, 'debug',0);
    [shape1ToShape2 shape2ToShape1 C] = calcP2PFromC(s{1}, s{kk}, C, s{1}.evecs, s{kk}.evecs, 'debug', 0,'numRefinements', 30);
    Cs{kk} = C;
    Ds{kk} = C'*C;
    Ds{kk} = Ds{kk}(:);
end
Ds = cell2mat(Ds);
Ds = Ds';