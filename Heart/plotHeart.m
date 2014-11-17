function [] = plotHeart( filename )
    addpath('../toolbox_fast_marching');
    addpath('../toolbox_fast_marching/toolbox');
    addpath('../toolbox_fast_marching/data');
   heart = load(filename);
   NFrames = size(heart.X, 1);
   X = heart.X;
   Y = heart.Y;
   Z = heart.Z;
   heart.X = X;
   heart.Y = Z;
   heart.Z = Y;
   for ii = 5:5
       clf;
       scatter3(heart.X(ii, :), heart.Y(ii, :), heart.Z(ii, :));
       xlim([min(heart.X(:)) - 10, max(heart.X(:)) + 10]);
       ylim([min(heart.Y(:)) - 10, max(heart.Y(:)) + 10]);
       zlim([min(heart.Z(:)) - 10, max(heart.Z(:)) + 10]);
       view(-56, 4);
       hold on;
       numberStrings = cellstr(num2str((0:11)'));
       locs = [heart.X(ii, :)' heart.Y(ii, :)' heart.Z(ii, :)']
       text(heart.X(ii, :), heart.Y(ii, :), heart.Z(ii, :), numberStrings);
       xlabel('X');
       ylabel('Y');
       zlabel('Z');
       for jj = 1:size(heart.edges, 1)
           i1 = heart.edges(jj, 1);
           i2 = heart.edges(jj, 2);
           plot3(heart.X(ii, [i1, i2]), heart.Y(ii, [i1, i2]), heart.Z(ii, [i1, i2]), 'b');
       end
       pause(0.1);
       print('-dpng', '-r100', sprintf('%i.png', ii));
   end
end