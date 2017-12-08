function [present, err] = resultsPresent(path)
    % Determines if valid results exist in the provided directory
    err = [];
    if exist(path) ~=7
        err = ['The folder ''' path ''' does not exist']
    elseif ~exist(fullfile(path, 'config.xml'))
        err = 'The file ''config.xml'' could not be found';
    elseif ~exist(fullfile(path, 'preprocessed.mat'))
        err = 'The file ''preprocessed.mat'' could not be found';
    elseif ~exist(fullfile(path, 'diff_matrix.mat'))
        err = 'The file ''diff_matrx.mat'' could not be found';
    elseif ~exist(fullfile(path, 'matching.mat'))
        err = 'The file ''matching.mat'' could not be found';
    end
    present = isempty(err);
end
