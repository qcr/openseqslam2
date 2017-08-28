classdef SeqSLAMInstance < handle

    properties
        config;
        results = emptyResults();

        listeningUI = false;
        callbackUIReady;
        callbackUIUpdate;
    end

    methods
        function obj = SeqSLAMInstance(config)
            obj.config = config;
            obj.loadResults();
        end

        function attachUI(obj, readyCallback, updateCallback)
            obj.callbackUIReady = readyCallback;
            obj.callbackUIUpdate = updateCallback;
            obj.listeningUI = true;
        end

        function loadResults(obj)
            % Bail if there are no existing results
            if ~ConfigIOGUI.containsResults(obj.config.results.path)
                return;
            end

            % Load the config of the existing results
            fn = ResultsGUI.getFileName(config, ResultsGUI.FN_CONFIG);
            configResults = xml2settings(fn);

            % Go through each of the load options, loading only if BOTH
            % load requested AND config matches!
            % TODO
        end

        function run(obj)
            % Perform each of the 'do' actions, guarding against if they
            % already exist
            obj.doPreprocess();
            obj.doDifferenceMatrix();
            obj.doContrastEnhancement();
            obj.doMatching();
            obj.doThresholding();
        end

        function saveResults(obj)
            % Bail if there is no provided results directory (there should
            % always be one generally...)
            % TODO

            % Save the config
            % TODO

            % Save each of the results in their own separate '*.mat' file
            % TODO
        end
    end

    methods (Access = private)
        function doPreprocess(obj)
            % Cache processing settings (mainly to avoid typing...)
            settingsProcess = obj.config.seqslam.image_processing;

            % Repeat the same process for both the reference and query dataset
            datasets = {'reference', 'query'};
            for ds = 1:length(datasets)
                % Report to the UI if necessary
                if obj.listeningUI && obj.callbackUIReady( ...
                        ProgressGUI.STATE_PREPROCESS_REF + ds-1)
                    p = [];
                    p.state = ProgressGUI.STATE_PREPROCESS_REF + ds-1;
                    p.percent = 0;
                    obj.callbackUIUpdate(p);
                end

                % Cache dataset settings (mainly to avoid typing...)
                settingsDataset = obj.config.(datasets{ds});

                % Allocate memory for all of the processed images
                if strcmpi(settingsDataset.type, 'image')
                    indices = settingsDataset.image.index_start:...
                        settingsDataset.subsample_factor:...
                        settingsDataset.image.index_end;
                elseif strcmpi(settingsDataset.type, 'video')
                    indices = 1:settingsDataset.subsample_factor:...
                        settingsDataset.video.frames;
                end
                nImages = length(indices);
                c = settingsProcess.crop.(datasets{ds});
                if isempty(c)
                    nWidth = ...
                        settingsProcess.downsample.width;
                    nHeight = ...
                        settingsProcess.downsample.height;
                else
                    nWidth = c(3) - c(1);
                    nHeight = c(4) - c(2);
                end
                images = zeros(nHeight, nWidth, nImages, 'uint8');

                % Initialise everything related to dataset
                if strcmpi(settingsDataset.type, 'video')
                    v = VideoReader(settingsDataset.path);
                else
                    v = [];
                end
                
                % Loop over all of the image indices
                for k = 1:length(indices)
                    % Load next image
                    if ~isempty(v)
                        v.CurrentTime = floor(indices(k) / v.FrameRate);
                        img = v.readFrame();
                    else
                        imgNumStr = num2str(indices(k), ...
                            ['%0' num2str(numel(num2str( ...
                                settingsDataset.image.index_end))) 'd']);
                        img = imread([settingsDataset.path filesep() ...
                            settingsDataset.image.token_start ...
                            imgNumStr ...
                            settingsDataset.image.token_end]);
                    end

                    % Grayscale
                    img = rgb2gray(img);

                    % Resize
                    if ~isempty(settingsProcess.downsample.width) && ...
                        ~isempty(settingsProcess.downsample.height)
                        img = imresize(img, ...
                            [settingsProcess.downsample.height ...
                                settingsProcess.downsample.width], ...
                            settingsProcess.downsample.method);
                    end
                    
                    % Crop
                    crop = settingsProcess.crop.(datasets{ds});
                    if ~isempty(crop) && length(crop) == 4
                        img = img(crop(2):crop(4), crop(1):crop(3));
                    end

                    % Patch Normalisation
                    if ~isempty(settingsProcess.normalisation.length) && ...
                        ~isempty(settingsProcess.normalisation.mode)
                        img = patchNormalise(img, ...
                            settingsProcess.normalisation.length, ...
                            settingsProcess.normalisation.mode);
                    end

                    % Save the image to the processed image matrix
                    images(:,:,k) = img;

                    % Update the UI if necessary
                    if obj.listeningUI && obj.callbackUIReady( ...
                            ProgressGUI.STATE_PREPROCESS_REF + ds-1)
                        p = [];
                        p.state = ProgressGUI.STATE_PREPROCESS_REF + ds-1;
                        p.percent = k/length(indices)*100;
                        obj.callbackUIUpdate(p);
                    end
                end

                % Save the processed image matrix to the results
                obj.results.preprocessed.(datasets{ds}) = images;
            end
        end

        function doDifferenceMatrix(obj)
            % Report to the UI if necessary
            if obj.listeningUI && obj.callbackUIReady( ...
                    ProgressGUI.STATE_DIFF_MATRIX)
                p = [];
                p.state = ProgressGUI.STATE_DIFF_MATRIX;
                p.percent = 0;
                obj.callbackUIUpdate(p);
            end

            % Allocate memory for the difference matrix
            w = size(obj.results.preprocessed.query, 3);
            h = size(obj.results.preprocessed.reference, 3);
            matrix = zeros(h, w, 'single');

            % Calculate the difference matrix (loop over each query image)
            % TODO LESS DUMB, AND PARALLELISE!!!
            % TODO There is an assumption here that dimensions of reference
            % and query images are the same! Verify...
            ps = size(obj.results.preprocessed.reference,1) * ...
                size(obj.results.preprocessed.reference,2);
            for y = 1:h
                for x = 1:w
                    % Get difference image
                    d = single(obj.results.preprocessed.query(:,:,x)) - ...
                        single(obj.results.preprocessed.reference(:,:,y));

                    % Compute difference value
                    matrix(y,x) = sum(abs(d(:))) / ps;

                    % Report to the UI if necessary
                    if obj.listeningUI && obj.callbackUIReady( ...
                            ProgressGUI.STATE_DIFF_MATRIX)
                        p = [];
                        p.state = ProgressGUI.STATE_DIFF_MATRIX;
                        p.percent = ((y-1)*h+x) / (w*h) * 100;
                        obj.callbackUIUpdate(p);
                    end
                end
            end
            
            % Save the different matrix to the results
            obj.results.diff_matrix.base = matrix;
        end

        function doContrastEnhancement(obj)
            % Report to the UI if necessary
            if obj.listeningUI && obj.callbackUIReady( ...
                    ProgressGUI.STATE_DIFF_MATRIX_CONTRAST)
                p = [];
                p.state = ProgressGUI.STATE_DIFF_MATRIX_CONTRAST;
                p.percent = 0;
                obj.callbackUIUpdate(p);
            end

            % Allocate memory for contrast enhanced difference matrix
            matrix = zeros(size(obj.results.diff_matrix.base), 'single');

            % Loop over each row of the difference matrix
            % TODO LESS DUMB, AND PARALLELISE!!!
            r = obj.config.seqslam.diff_matrix.contrast.r_window;
            for x = 1:size(obj.results.diff_matrix.base,2)
                for y = 1:size(obj.results.diff_matrix.base,1)
                    % Compute limits
                    ya = max(1, y-r/2);
                    yb = min(size(matrix,1), y+r/2);

                    % Get enhanced value 
                    local = obj.results.diff_matrix.base(ya:yb,x);
                    matrix(y,x) = (obj.results.diff_matrix.base(y,x) - ...
                        mean(local)) / std(local);

                    % Report to the UI if necessary
                    if obj.listeningUI && obj.callbackUIReady( ...
                            ProgressGUI.STATE_DIFF_MATRIX_CONTRAST)
                        p = [];
                        p.state = ProgressGUI.STATE_DIFF_MATRIX_CONTRAST;
                        p.percent = ((x-1)*size(matrix,2)+y) / ...
                            numel(matrix) * 100;
                        obj.callbackUIUpdate(p);
                    end
                end
            end

            % Save the enhanced matrix (with the minimum value as 0)
            obj.results.diff_matrix.enhanced = matrix - min(min(matrix));
        end

        function doMatching(obj)
            % Report to the UI if necessary
            if obj.listeningUI && obj.callbackUIReady( ...
                    ProgressGUI.STATE_MATCHING)
                p = [];
                p.state = ProgressGUI.STATE_MATCHING;
                p.percent = 0;
                obj.callbackUIUpdate(p);
            end

            % Cache settings (save typing...)
            settingsMatch = obj.config.seqslam.matching;
            ds = settingsMatch.d_s;
            num_qs = size(obj.results.diff_matrix.enhanced,2);
            num_rs = size(obj.results.diff_matrix.enhanced,1);

            % Allocate memory for the matching scores
            matches = NaN(num_qs,2);

            % Figure out which relative trajectories are actually going to be
            % a unique path (so we only ever check a path once)
            moves = settingsMatch.trajectories.v_min * ds:... 
                settingsMatch.trajectories.v_max * ds;
            vs = moves / ds;

            % Get a matrix of relative x and y indices to test (we are centring
            % the window around the query image, looking ds/2 forward and back)
            q_indices = repmat([0:ds], length(vs), 1) - ds/2;
            r_indices = floor(repmat(vs', 1, ds+1) .* q_indices);

            % Loop from the query image number ds/2+1, through until the 
            % length-ds/2 image number
            r_scores = zeros(num_rs, 1);
            dbgI = 0;
            for q = (ds/2+1):(num_qs-ds/2)
                % Set q indices
                qs = q_indices + q; % We know these are all 'safe'...
                
                % Loop through each of the possible references, getting a score
                % for the best trajectory
                for r = 1:num_rs
                    % Set r indices (deleting rows where there is an
                    % invalid value)
                    rs = r_indices + r;
                    rs = rs(all(rs > 0 & rs <= num_rs, 2),:);

                    % Get the minimum score for this reference image
                    if isempty(rs)
                        r_scores(r) = NaN();
                        obj.results.matches.dbg(r,q).empty = true;
                    else
                        s1 = sub2ind(size(obj.results.diff_matrix.enhanced), ...
                            rs(:), qs(1:numel(rs))'); % Indices
                        s2 = obj.results.diff_matrix.enhanced(s1); % Scores
                        s3 = reshape(s2, size(rs)); % Reshaped scores
                        r_scores(r) = min(sum(s3,2));
                        obj.results.matches.dbg(r,q).rs = rs;
                        obj.results.matches.dbg(r,q).qs = qs;
                        obj.results.matches.dbg(r,q).s1 = s1;
                        obj.results.matches.dbg(r,q).s2 = s2;
                        obj.results.matches.dbg(r,q).s3 = s3;
                    end

                    % Report to the UI if necessary
                    if obj.listeningUI && obj.callbackUIReady( ...
                            ProgressGUI.STATE_MATCHING)
                        p = [];
                        p.state = ProgressGUI.STATE_MATCHING;
                        p.percent = ((q-1-ds/2)*num_rs + r) / ...
                            ((num_qs-ds)*num_rs) * 100;
                        obj.callbackUIUpdate(p);
                    end
                    dbgI = dbgI + 1;
                end

                % Get min score, and second smallest outside the window
                [min_score, min_idx] = min(r_scores);
                is = 1:num_rs;
                window_min = min(r_scores( ...
                    is(is < min_idx-settingsMatch.criteria.r_window/2 | ...
                        is > min_idx+settingsMatch.criteria.r_window/2) ...
                    ));

                % Store the min index, and the factor to second min
                matches(q,:) = [min_idx window_min/min_score];
            end

            % Save the best match index, and "best factor" for each query
            obj.results.matches.all = matches;
        end

        function doThresholding(obj)
            % Report to the UI if necessary
            if obj.listeningUI && obj.callbackUIReady( ...
                    ProgressGUI.STATE_MATCHING_FILTERING)
                p = [];
                p.state = ProgressGUI.STATE_MATCHING_FILTERING;
                p.percent = 0;
                obj.callbackUIUpdate(p);
            end

            % Mask out with NaNs those that are below threshold
            mask = single(obj.results.matches.all(:,2) > ...
                    obj.config.seqslam.matching.criteria.u);
            mask(mask == 0) = NaN();

            % Save the thresholded results
            obj.results.matches.mask = mask;
            obj.results.matches.thresholded = ...
                obj.results.matches.all(:,1) .* mask;

            % Report to the UI if necessary
            if obj.listeningUI && obj.callbackUIReady( ...
                    ProgressGUI.STATE_DONE)
                p = [];
                p.state = ProgressGUI.STATE_DONE;
                obj.callbackUIUpdate(p);
            end
        end
    end
end
