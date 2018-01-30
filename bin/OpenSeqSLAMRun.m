function results = OpenSeqSLAMRun(config, varargin)
    % Parse variable input
    % NOTE: Secondary validation is assumed to be done PRIOR
    valsMode = {'graphical', 'text'};
    p = inputParser();
    addParameter(p, 'mode', 'graphical', ...
        @(x) ischar(validatestring(x, valsMode)));
    addParameter(p, 'batch', false, ...
        @(x) validateattributes(x, {'logical'}, {'scalar'}));
    addParameter(p, 'batch_param', '', ...
        @(x) validateattributes(x, {'char'}, {'scalartext'}));
    addParameter(p, 'batch_values', [], ...
        @(x) validateattributes(x, {'numeric'}, {'vector'}));
    parse(p, varargin{:});
    params = p.Results;

    % Construct a list of jobs (there will only be one for single)
    if params.batch
        jobs = arrayfun(@(x) {params.batch_param, x}, params.batch_values, ...
            'uni', false);
    else
        jobs = {{}};
    end

    % Start running through each of the jobs
    for k = 1:length(jobs)
        j = jobs{k}
        if ~isempty(j)
            c = setDeepField(config, j{1}, j{2});
            s1 = strsplit(j{1}, '.');
            s2 = strrep(num2str(j{2}), '.', '_');
            c.results.path = fullfile(config.results.path, [s1{end} '-' s2]);
            c.results.path
        end

        % TODO broken from here down...
        if strcmpi(params.mode, valsMode{2})
            % TODO
            fprintf('Batching...\n');
        else
            % Create the progress GUI
            ioprogress = ProgressGUI(config);

            % Run the SeqSLAM instance until done
            ioprogress.run();

            % Save the results
            results = ioprogress.results;
        end
    end
    results = []
end
