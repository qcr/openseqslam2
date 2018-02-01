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
        @(x) validateattributes(x, {'char', 'numeric'}, {'vector'}));
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

    % Run the SeqSLAM process, and get the results
    if params.batch
        results = OpenSeqSLAMRun(config, 'mode', params.progress, 'batch', ...
            params.batch, 'batch_param', params.batch_param, 'batch_values', ...
            params.batch_values);
    else
        results = OpenSeqSLAMRun(config, 'mode', params.progress);
    end

    % Run the appropriate results validation UI if requested
    if params.results_ui
        [results, config] = OpenSeqSLAMResults(results, config);
    end
end
