classdef SeqSLAMInstance < handle

    properties
        config;
        results = emptyResults();

        listeningUI = false;
        cbPercentReady;
        cbPercentUpdate;
        cbMainReady;
        cbMainUpdate;
    end

    methods
        function obj = SeqSLAMInstance(config)
            obj.config = config;
            obj.loadResults();
        end

        function attachUI(obj, ui)
            if ~strcmp('ProgressGUI', class(ui))
                return;
            end

            obj.cbPercentReady = @ui.refreshPercentDue;
            obj.cbPercentUpdate = @ui.refreshPercent;
            obj.cbMainReady = @ui.refreshMainDue;
            obj.cbMainUpdate = @ui.refreshMain;
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
            obj.preprocess();
            obj.differenceMatrix();
            obj.contrastEnhancement();
            obj.matching();
            obj.thresholding();
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

    methods (Static)
        function [imgOut, imgs] = preprocessSingle(img, s, dsName, full)
            % Grayscale
            imgG = rgb2gray(img);

            % Resize
            imgCR = imgG;
            if ~isempty(s.downsample.width) && ~isempty(s.downsample.height)
                imgCR = imresize(imgCR, ...
                    [s.downsample.height s.downsample.width], ...
                    s.downsample.method);
            end

            % Crop
            crop = s.crop.(dsName);
            if ~isempty(crop) && length(crop) == 4
                imgCR = imgCR(crop(2):crop(4), crop(1):crop(3));
            end

            % Patch Normalisation
            if ~isempty(s.normalisation.length) && ...
                    ~isempty(s.normalisation.mode)
                imgOut = patchNormalise(imgCR, s.normalisation.length, ...
                    s.normalisation.mode);
            end

            % Return the full results only if requested
            if full
                imgs = {imgG, imgCR};
            else
                imgs = [];
            end
        end
    end

    methods (Access = private)
        function preprocess(obj)
            % Cache processing settings (mainly to avoid typing...)
            settingsProcess = obj.config.seqslam.image_processing;

            % Repeat the same process for both the reference and query dataset
            datasets = {'reference', 'query'};
            for ds = 1:length(datasets)
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
                        v.CurrentTime = datasetFrameInfo(indices(k)-1, ...
                            v.FrameRate, 0);
                        img = v.readFrame();
                    else
                        imgPath = datasetImageInfo(settingsDataset.path, ...
                            settingsDataset.image.token_start, ...
                            settingsDataset.image.token_end, ...
                            indices(k), settingsDataset.image.index_end, ...
                            0);
                        img = imread(imgPath);
                    end

                    % Preprocess the image
                    state = ProgressGUI.STATE_PREPROCESS_REF + ds-1;
                    [imgOut, imgs] = SeqSLAMInstance.preprocessSingle(img, ...
                        settingsProcess, datasets{ds}, ...
                        obj.listeningUI && obj.cbMainReady(state));

                    % Save the image to the processed image matrix
                    images(:,:,k) = imgOut;

                    % Update the UI if necessary
                    if obj.uiWaiting(state)
                        perc = k/length(indices)*100;
                        if obj.cbMainReady(state) && ~isempty(imgs)
                            p = [];
                            p.state = state;
                            p.percent = perc;
                            p.image_init = img;
                            p.image_grey = imgs{1};
                            p.image_crop_resized = imgs{2};
                            p.image_out = imgOut;
                            p.image_num = k;
                            if ~isempty(v)
                                p.image_details = datasetFrameInfo( ...
                                    indices(k)-1, v.FrameRate, 1, ...
                                    settingsDataset.path, k);
                            else
                                p.image_details = datasetImageInfo( ...
                                    settingsDataset.path, ...
                                    settingsDataset.image.token_start, ...
                                    settingsDataset.image.token_end, ...
                                    indices(k), ...
                                    settingsDataset.image.index_end, 1, k);
                            end
                            obj.cbMainUpdate(p);
                        else
                            obj.cbPercentUpdate(perc);
                        end
                    end
                end

                % Save the processed image matrix to the results, and indices
                obj.results.preprocessed.(datasets{ds}) = images;
                obj.results.preprocessed.([datasets{ds} '_indices']) = indices;
            end
        end

        function differenceMatrix(obj)
            % Allocate memory for the difference matrix
            w = size(obj.results.preprocessed.query, 3);
            h = size(obj.results.preprocessed.reference, 3);
            matrix = NaN(h, w, 'single');

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
                    if obj.uiWaiting(ProgressGUI.STATE_DIFF_MATRIX)
                        perc = ((y-1)*w+x) / (w*h) * 100;
                        if obj.cbMainReady( ...
                                ProgressGUI.STATE_DIFF_MATRIX)
                            p = [];
                            p.state = ProgressGUI.STATE_DIFF_MATRIX;
                            p.percent = perc;
                            p.diff_matrix = matrix;
                            obj.cbMainUpdate(p);
                        else
                            obj.cbPercentUpdate(perc);
                        end
                    end
                end
            end
            
            % Save the different matrix to the results
            obj.results.diff_matrix.base = matrix;
        end

        function contrastEnhancement(obj)
            % Allocate memory for contrast enhanced difference matrix
            matrix = NaN(size(obj.results.diff_matrix.base), 'single');

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
                    if obj.uiWaiting(ProgressGUI.STATE_DIFF_MATRIX_CONTRAST)
                        perc = ((x-1)*size(matrix,1)+y) / ...
                            numel(matrix) * 100;
                        if obj.cbMainReady( ...
                                ProgressGUI.STATE_DIFF_MATRIX_CONTRAST)
                            p = [];
                            p.state = ProgressGUI.STATE_DIFF_MATRIX_CONTRAST;
                            p.percent = perc;
                            mask = isnan(matrix);
                            temp = matrix;
                            temp(isnan(temp)) = 0;
                            p.diff_matrix = temp + ...
                                mask .* obj.results.diff_matrix.base;
                            obj.cbMainUpdate(p);
                        else
                            obj.cbPercentUpdate(perc);
                        end
                    end
                end
            end

            % Save the enhanced matrix (with the minimum value as 0)
            obj.results.diff_matrix.enhanced = matrix - min(min(matrix));
        end

        function matching(obj)
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
            r_scores = NaN(num_rs, 1);
            r_trajs = NaN(num_rs, size(r_indices,2));
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
                    % (if there is one)
                    if ~isempty(rs)
                        s1 = sub2ind(size(obj.results.diff_matrix.enhanced), ...
                            rs(:), reshape(qs(1:size(rs,1),:), [], 1)); %Indices
                        s2 = obj.results.diff_matrix.enhanced(s1); % Scores
                        s3 = reshape(s2, size(rs)); % Reshaped scores
                        [r_scores(r), ind] = min(sum(s3,2));
                        r_trajs(r,:) = rs(ind,:);
                    end

                    % Report to the UI if necessary
                    if obj.uiWaiting(ProgressGUI.STATE_MATCHING)
                        perc = ((q-1-ds/2)*num_rs + r) / ...
                            ((num_qs-ds)*num_rs) * 100;
                        if obj.cbMainReady( ...
                                ProgressGUI.STATE_MATCHING)
                            p = [];
                            p.state = ProgressGUI.STATE_MATCHING;
                            p.percent = perc;
                            p.q = q;
                            p.r = r;
                            p.qs = qs(1,:);
                            p.rs = r_trajs(r,:);
                            p.diff_matrix = obj.results.diff_matrix.enhanced;
                            obj.cbMainUpdate(p);
                        else
                            obj.cbPercentUpdate(perc);
                        end
                    end
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

        function thresholding(obj)
            % Report to the UI if necessary
            if obj.uiWaiting(ProgressGUI.STATE_MATCHING_FILTERING)
                p = [];
                p.state = ProgressGUI.STATE_MATCHING_FILTERING;
                p.percent = 0;
                obj.cbMainUpdate(p);
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
            if obj.uiWaiting(ProgressGUI.STATE_DONE)
                p = [];
                p.state = ProgressGUI.STATE_DONE;
                obj.cbMainUpdate(p);
            end
        end

        function ret = uiWaiting(obj, state)
            ret = obj.listeningUI && (obj.cbPercentReady(state) || ...
                obj.cbMainReady(state));
        end
    end
end
