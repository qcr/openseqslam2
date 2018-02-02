function [results, config] = OpenSeqSLAM2(varargin)
    % Add the toolbox to the path
    run(fullfile(fileparts(which('OpenSeqSLAM2')), 'tools', 'toolboxInit'));

    % Construct the input parser, and parse the provided arguments
    valsProgress = {'', 'graphical', 'console'};
    p = inputParser();
    addParameter(p, 'config', '', ...
        @(x) validateattributes(x, {'char'}, {'vector'}));
    addParameter(p, 'progress', '', ...
        @(x) ischar(validatestring(x, valsProgress)));
    addParameter(p, 'results_ui', true, ...
        @(x) validateattributes(x, {'logical'}, {'scalar'}));
    addParameter(p, 'batch_param', '', ...
        @(x) validateattributes(x, {'char'}, {'scalartext'}));
    addParameter(p, 'batch_values', [], ...
        @(x) validateattributes(x, {'numeric'}, {'vector'}));
    addParameter(p, 'ground_truth', '', ...
        @(x) validateattributes(x, {'cell'}, {'vector'}));
    parse(p, varargin{:});
    params = p.Results;

    % Perform any secondary validation, failing if an impossible configuration
    % was requested
    if isempty(params.config)
        config = emptyConfig();
    elseif strcmpi(params.config, 'default')
        config = xml2settings( ...
            fullfile(toolboxRoot(), '.config', 'default.xml'));
    else
        config = xml2settings(params.config);
    end
    if xor(isempty(params.batch_param), isempty(params.batch_values))
        error(['To run in batch mode, BOTH ''batch_param'' and ' ...
            '''batch_values'' must be specified']);
    elseif ~isempty(params.batch_param) && ~isempty(params.batch_values)
        [exists, value] = findDeepField(config, params.batch_param);
        if ~exists
            error(['No config parameter named ''' params.batch_param ...
                ''' could be found for the batch operation.']);
        end
        validateattributes(value, {'numeric'}, {'scalar'}, '', params.batch_param);
        params.batch = true;
    else
        params.batch = false;
    end
    params.progress = validatestring(params.progress, valsProgress);
    if isempty(params.progress)
        if params.batch
            params.progress = valsProgress{3}; % console default for batch
        else
            params.progress = valsProgress{2}; % graphical default for single
        end
    end
    if ~isempty(params.ground_truth)
        if ischar(params.ground_truth{1})
            [p, f, e] = fileparts(params.ground_truth{1});
            if strcmpi(e, '.csv') && length(params.ground_truth) > 1
                error(['Invalid ground truth *.csv specification. Only 1 ' ...
                    'character vector is expected (the filename)']);
            elseif strcmpi(e, '.mat') && (length(params.ground_truth) == 1 ...
                    || length(params.ground_truth) > 2 || ...
                    ~ischar(params.ground_truth{2}))
                error(['Invalid ground truth *.mat specification. A ' ...
                    'char vector for filename, and char vector for variable' ...
                    ' name is expected.']);
            elseif ~strcmpi(e, '.mat') && ~strcmpi(e, '.csv')
                error(['Invalid ground truth file requested. Only *.csv ' ...
                    'and *.mat are supported.']);
            end
            if strcmpi(e, '.mat')
                params.ground_truth_type = GroundTruthPopup.SOURCE_MAT;
            else
                params.ground_truth_type = GroundTruthPopup.SOURCE_CSV;
            end
        elseif length(params.ground_truth) > 2 || ...
                ~isscalar(params.ground_truth{1}) || ...
                ~isnumeric(params.ground_truth{1}) || ...
                ~isscalar(params.ground_truth{2}) || ...
                ~isnumeric(params.ground_truth{2})
            error(['Invalid ground truth velocity / tolerance spec. Two ' ...
                'scalar values (for vel and tol respectively) are expected.']);
        else
            params.ground_truth_type = GroundTruthPopup.SOURCE_VEL;
        end
    end

    % Obtain a valid config (either from GUI, or loading specified XML)
    if isempty(params.config)
        config = OpenSeqSLAMConfig();
        if isempty(config)
            error('No configuration was selected in the GUI. Aborting.');
        end
    else
        config = xml2settings(params.config);
        if isempty(config)
            error(['Loading configuration from ''' params.config ''' failed.']);
        end
    end

    % Construct valid ground truth data (either from GUI, or inflating request)
    sz = [length(SeqSLAMInstance.numbers(config.query)), ...
        length(SeqSLAMInstance.numbers(config.reference))];
    if params.batch && isempty(params.ground_truth)
        gtui = GroundTruthPopup(emptyGroundTruth(), sz);
        uiwait(gtui.hFig);
        if isempty(gtui.selectedMatrix)
            error('No valid ground truth matrix was selected. Aborting.');
        end
        ground_truth = gtui.gt;
    elseif params.batch
        ground_truth = emptyGroundTruth();
        if params.ground_truth_type == GroundTruthPopup.SOURCE_VEL
            [ground_truth.matrix, err] = GroundTruthPopup.gtFromVel( ...
                params.ground_truth{1}, params.ground_truth{2}, sz);
        elseif params.ground_truth_type == GroundTruthPopup.SOURCE_CSV
            [ground_truth.matrix, err] = GroundTruthPopup.gtFromCSV( ...
                params.ground_truth{1}, sz);
        elseif params.ground_truth_type == GroundTruthPopup.SOURCE_MAT
            [ground_truth.matrix, err] = GroundTruthPopup.gtFromMAT( ...
                params.ground_truth{1}, params.ground_truth{2}, sz);
        end
        if isempty(err)
            ground_truth.matrix = ground_truth.matrix > 0;
            ground_truth.type = params.ground_truth_type;
            if ground_truth.type == GroundTruthPopup.SOURCE_VEL
                ground_truth.velocity.vel = params.ground_truth{1};
                ground_truth.velocity.tol = params.ground_truth{2};
            else
                ground_truth.file.path = params.ground_truth{1};
                if ground_truth.type == GroundTruthPopup.SOURCE_MAT
                    ground_truth.file.var = params.ground_truth{2};
                end
            end
        else
            error(err);
        end;
    end

    % Run the SeqSLAM process, and get the results
    if params.batch
        results = OpenSeqSLAMRun(config, 'mode', params.progress, 'batch', ...
            params.batch, 'batch_param', params.batch_param, 'batch_values', ...
            params.batch_values);

        % Calculate precision recall for results
        results.ground_truth = ground_truth;
        for k = 1:length(results.tests)
            [p, r] = calcPR(results.tests(k).matching.selected.matches, ...
                ground_truth.matrix);
            results.precisions(k) = p;
            results.recalls(k) = r;
        end
    else
        results = OpenSeqSLAMRun(config, 'mode', params.progress);
    end
    return;

    % Run the appropriate results validation UI if requested
    if params.results_ui
        [results, config] = OpenSeqSLAMResults(results, config);
    end
end
