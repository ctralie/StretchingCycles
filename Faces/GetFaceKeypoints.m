function [I, dims] = GetFaceKeypoints(filename)
    % read image from input file
    im=imread(filename);
    dims = size(im);
    
    % load model and parameters, type 'help xx_initialize' for more details
    [DM,TM,option] = xx_initialize;
    
    
    % perform face alignment in one image, type 'help xx_track_detect' for
    % more details
    faces = DM{1}.fd_h.detect(im,'MinNeighbors',option.min_neighbors,...
      'ScaleFactor',1.2,'MinSize',option.min_face_size);

    output = xx_track_detect(DM,TM,im,faces{1},option);
    I = zeros(size(output.pred, 1), 2);
    if size(I, 1) > 0
        I(:, 1) = dims(1) - output.pred(:, 2);
        I(:, 2) = output.pred(:, 1);
    end
    
%     imshow(im);
%     hold on;
%     plot(output.pred(:, 1), output.pred(:, 2), 'g.');
end