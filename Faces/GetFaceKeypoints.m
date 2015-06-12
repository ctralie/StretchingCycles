function [I, dims, predout] = GetFaceKeypoints(filename, pred)
    % read image from input file
    im=imread(filename);
    dims = size(im);
    [DM,TM,option] = xx_initialize;
    
    output = xx_track_detect(DM,TM,im,pred,option);
    predout = output.pred;
    I = zeros(size(output.pred, 1), 2);
    if size(I, 1) > 0
        I(:, 1) = dims(1) - output.pred(:, 2);
        I(:, 2) = output.pred(:, 1);
    end
end