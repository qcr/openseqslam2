function l = datasetImageList(datasetConfig, indices)
    % Get all relevant information for the dataset
    path = datasetConfig.path;
    info = datasetConfig.(datasetConfig.type);
    isVideo = strcmp(datasetConfig.type, 'video');

    % Populate the list
    l = cell(length(indices),1);
    if isVideo
        l = arrayfun( ...
            @(x) datasetFrameInfo(indices(x), info.frame_rate, 1, ...
            path, x), ...
            1:length(indices), 'UniformOutput', false);
    else
        l = arrayfun( ...
            @(x) datasetPictureInfo(path, info.token_start, ...
            info.token_end, indices(x), info.index_end, 1, x), ...
            1:length(indices), 'UniformOutput', false);
    end
end
