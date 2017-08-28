classdef SeqSLAMInstance < handle

    properties
        config;
        results;
    end

    methods
        function obj = SeqSLAMInstance(config)
            obj.config = config;
            loadResults();
        end

        function loadResults(obj)
            % Bail if there are no existing results
            if ~ConfigIOGUI.containsResults(config.results.path)
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
            % Repeat the same process for both the reference and query dataset
            datasets = {'reference', 'query'};
            for ds = 1:length(datasets)
                % Allocate memory for all of the processed images
                results.preprocessed.(dataset{ds}) 

                % Loop over all of the images (use a while loop to accomodate
                % for how VideoReader works...)
                % TODO
                    % Grayscale
                    % TODO

                    % Resize
                    % TODO

                    % Crop
                    % TODO

                    % Patch Normalisation
                    % TODO
        end

        function doDifferenceMatrix(obj)
            % Allocate memory for the difference matrix
            % TODO

            % Calculate the difference matrix (loop over each query image)
            % TODO
                % Get difference image
                % TODO

                % Computer difference value
                % TODO
        end

        function doContrastEnhancement(obj)
            % Allocate memory for contrast enhanced difference matrix
            % TODO

            % Loop over each row of the difference matrix
            % TODO
                % Compute limits
                % TODO

                % Get enhanced values for row
                % TODO

            % Let the minimum be 0 (TODO check this...)
            % TODO
        end

        function doMatching(obj)
            % Allocate memory for the matching scores
            % TODO

            % Figure out which relative trajectories are actually going to be
            % a unique path (so we only ever check a path once)
            % TODO

            % Loop from the ds+1 through till the end of the query dataset
            % TODO
                % Searches...
                % TODO

            % Find minimum score, and 2nd smallest score outside a window...
            % TODO
        end
    end
end
