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

            % Crop
            imgCR = imgG;
            crop = s.crop.(dsName);
            if ~isempty(crop) && length(crop) == 4
                imgCR = imgCR(crop(2):crop(4), crop(1):crop(3));
            end

            % Resize
            if ~isempty(s.downsample.width) && ~isempty(s.downsample.height)
                imgCR = imresize(imgCR, ...
                    [s.downsample.height s.downsample.width], ...
                    s.downsample.method);
            end

            % Patch Normalisation
            if ~isempty(s.normalisation.threshold) && ...
                    ~isempty(s.normalisation.strength)
                imgOut = patchNormalise(imgCR, s.normalisation.threshold, ...
                    s.normalisation.strength);
            end

            % Return the full results only if requested
            if full
                imgs = {imgG, imgCR};
            else
                imgs = [];
            end
        end

        function indices = indices(datasetConfig)
            if strcmpi(datasetConfig.type, 'image')
                indices = datasetConfig.image.index_start:...
                    datasetConfig.subsample_factor:...
                    datasetConfig.image.index_end;
            elseif strcmpi(datasetConfig.type, 'video')
                indices = 1:datasetConfig.subsample_factor:...
                    datasetConfig.video.frames;
            end
        end

        function us = usFromMatches(scores, window)
            % Start with the best scores
            [best_scores, best_idx] = min(scores);

            % Construct a NaN mask representing the windowed regions
            mask = ones(size(scores));
            for k = 1:length(best_idx)
                a = max(1, best_idx(k)-round(window/2));
                b = min(size(scores,1), best_idx(k)+round(window/2));
                mask(a:b,k) = NaN();
            end

            % Compute the us from the windowed mins
            us = min(scores.*mask) ./ best_scores;
        end

        function thresholded = thresholdWindowed(matches, window, u)
            % Get the u scores, and best indices
            us = SeqSLAMInstance.usFromMatches(matches.min_scores, window);
            [best_scores, best_idx] = min(matches.min_scores);

            % Mask out with NaNs those that are below threshold
            mask = single(us > u);
            mask(mask == 0) = NaN();

            % Save the thresholding results
            thresholded.mask = mask;
            thresholded.matches = best_idx .* mask;
            thresholded.trajectories = ...
                matches.best_trajectories .* ...
                repmat(mask', 1, ...
                size(matches.best_trajectories,2), ...
                size(matches.best_trajectories,3));
        end

        function thresholded = thresholdBasic(matches, threshold)
            % Get the best scores for each query images (and indices)
            [best_scores, best_idx] = min(matches.min_scores);

            % Mask out with NaNs those that are above threshold
            % Create a maske where NaNs represent the scores above threshold
            mask = single(best_scores < threshold);
            mask(mask == 0) = NaN();

            % Save the thresholding results
            thresholded.mask = mask;
            thresholded.matches = best_idx .* mask;
            thresholded.trajectories = ...
                matches.best_trajectories .* ...
                repmat(mask', 1, ...
                size(matches.best_trajectories,2), ...
                size(matches.best_trajectories,3));
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

                % Get the indices
                indices = SeqSLAMInstance.indices(settingsDataset);

                % Allocate memory for all of the processed images
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
                    % Calculate percent if needed (used in multiple places)
                    perc = [];
                    if obj.listeningUI
                        perc = k/length(indices)*100;
                    end

                    % Load next image
                    img = datasetOpenImage(settingsDataset, k, indices, v);

                    % Preprocess the image
                    state = ProgressGUI.STATE_PREPROCESS_REF + ds-1;
                    [imgOut, imgs] = SeqSLAMInstance.preprocessSingle(img, ...
                        settingsProcess, datasets{ds}, ...
                        obj.listeningUI && obj.cbMainReady(state, perc));

                    % Save the image to the processed image matrix
                    images(:,:,k) = imgOut;

                    % Update the UI if necessary
                    if obj.listeningUI
                        if obj.cbMainReady(state, perc) && ~isempty(imgs)
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
                                p.image_details = datasetPictureInfo( ...
                                    settingsDataset.path, ...
                                    settingsDataset.image.token_start, ...
                                    settingsDataset.image.token_end, ...
                                    indices(k), ...
                                    settingsDataset.image.index_end, 1, k);
                            end
                            obj.cbMainUpdate(p);
                        elseif obj.cbPercentReady(state, perc)
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
                    if obj.listeningUI
                        perc = ((y-1)*w+x) / (w*h) * 100;
                        if obj.cbMainReady( ...
                                ProgressGUI.STATE_DIFF_MATRIX, perc)
                            p = [];
                            p.state = ProgressGUI.STATE_DIFF_MATRIX;
                            p.percent = perc;
                            p.diff_matrix = matrix;
                            obj.cbMainUpdate(p);
                        elseif obj.cbPercentReady( ...
                                ProgressGUI.STATE_DIFF_MATRIX, perc)
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
                    if obj.listeningUI
                        perc = ((x-1)*size(matrix,1)+y) / ...
                            numel(matrix) * 100;
                        if obj.cbMainReady( ...
                                ProgressGUI.STATE_DIFF_MATRIX_CONTRAST, perc)
                            p = [];
                            p.state = ProgressGUI.STATE_DIFF_MATRIX_CONTRAST;
                            p.percent = perc;
                            mask = isnan(matrix);
                            temp = matrix;
                            temp(isnan(temp)) = 0;
                            p.diff_matrix = temp + ...
                                mask .* obj.results.diff_matrix.base;
                            obj.cbMainUpdate(p);
                        elseif obj.cbPercentReady( ...
                                ProgressGUI.STATE_DIFF_MATRIX_CONTRAST, perc)
                            obj.cbPercentUpdate(perc);
                        end
                    end
                end
            end

            % Save the enhanced matrix (with the minimum value as 0)
            obj.results.diff_matrix.enhanced = matrix - min(min(matrix));
        end

        function matching(obj)
            % ds is split between searching forwards and backwards from the
            % current query image. If ds is odd, then the search is floor(ds/2)
            % back and forwards (giving a total trajectory length of ds). If
            % ds is even, then the search is floor(ds/2) back and floor(ds/2)-1
            % forwards (giving a total trajectory length of ds).

            % Cache settings (save typing...)
            settingsMatch = obj.config.seqslam.matching;
            ds = settingsMatch.trajectory.d_s;
            num_qs = size(obj.results.diff_matrix.enhanced,2);
            num_rs = size(obj.results.diff_matrix.enhanced,1);

            % Allocate memory for min matching scores, and best trajectories
            matches = NaN(num_rs, num_qs);
            trajs = NaN(num_qs, 2, ds); % q trajectories = r & q coords

            % Get matrices corresponding to all of the possible relative search
            % trajectories
            vs = settingsMatch.trajectory.v_min : ...
                settingsMatch.trajectory.v_step : ...
                settingsMatch.trajectory.v_max;
            qs_rel = repmat([0:ds-1], length(vs), 1) - floor(ds/2);
            rs_rel = round(repmat(vs', 1, ds) .* qs_rel);

            % Only bother with the velocities which produce unique trajectories
            [x, iA, iC] = unique(rs_rel, 'rows', 'stable');
            qs_rel = qs_rel(iA,:);
            rs_rel = rs_rel(iA,:);
            q_rel_min = min(qs_rel(1,:));
            q_rel_max = max(qs_rel(1,:));

            % Loop through each of the query images that allow the requested
            % trajectory window of size ds, finding the best trajectory for
            % each reference image
            r_scores = NaN(num_rs, 1);
            r_trajs = NaN(num_rs, ds);
            for q = (-q_rel_min + 1) : (num_qs - q_rel_max)
                % Set q indices
                qs = qs_rel + q; % We know these are all 'safe'...

                % Loop through each of the possible references, getting a score
                % for the best trajectory
                for r = 1:num_rs
                    % Set r indices (deleting rows where there is an
                    % invalid value)
                    rs = rs_rel + r;
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
                    if obj.listeningUI
                        perc = ((q-1-ds/2)*num_rs + r) / ...
                            ((num_qs-ds)*num_rs) * 100;
                        if obj.cbMainReady( ...
                                ProgressGUI.STATE_MATCHING, perc)
                            p = [];
                            p.state = ProgressGUI.STATE_MATCHING;
                            p.percent = perc;
                            p.q = q;
                            p.r = r;
                            p.qs = qs(1,:);
                            p.rs = r_trajs(r,:);
                            p.diff_matrix = obj.results.diff_matrix.enhanced;
                            obj.cbMainUpdate(p);
                        elseif obj.cbPercentReady( ...
                                ProgressGUI.STATE_MATCHING, perc)
                            obj.cbPercentUpdate(perc);
                        end
                    end
                end

                % Store all of the r_scores, and trajectory of the minimum score
                matches(:,q) = r_scores;
                [x, idx] = min(r_scores);
                trajs(q,:,:) = [qs(1,:); r_trajs(idx,:)];
            end

            % Save all of the minimum scores, and best trajectories
            obj.results.matching.all.min_scores = matches;
            obj.results.matching.all.best_trajectories = trajs;
        end

        function thresholding(obj)
            % Report to the UI if necessary
            if obj.listeningUI
                p = [];
                p.state = ProgressGUI.STATE_MATCHING_FILTERING;
                p.percent = 0;
                obj.cbMainUpdate(p);
            end

            % Perform the thresholding
            if strcmpi(obj.config.seqslam.matching.method, 'thresh')
                obj.results.matching.selected = ...
                    SeqSLAMInstance.thresholdBasic(obj.results.matching.all, ...
                    obj.config.seqslam.matching.method_thresh.threshold);
            else
                obj.results.matching.selected = ...
                    SeqSLAMInstance.thresholdWindowed( ...
                    obj.results.matching.all, ...
                    obj.config.seqslam.matching.method_window.r_window, ...
                    obj.config.seqslam.matching.method_window.u);
            end

            % Report to the UI if necessary
            if obj.listeningUI
                p = [];
                p.state = ProgressGUI.STATE_DONE;
                p.percent = 100;
                obj.cbMainUpdate(p);
            end
        end
    end
end
