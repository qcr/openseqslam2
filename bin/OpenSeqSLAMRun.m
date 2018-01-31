function results = OpenSeqSLAMRun(config, varargin)
    % Parse variable input
    % NOTE: Secondary validation is assumed to be done PRIOR
    valsMode = {'graphical', 'console'};
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
        % Do any required pre-processing for the job
        j = jobs{k};
        if ~isempty(j)
            c = setDeepField(config, j{1}, j{2});
            s1 = strsplit(j{1}, '.');
            s2 = strrep(num2str(j{2}), '.', '_');
            c.results.path = fullfile(config.results.path, [s1{end} '-' s2]);
        end

        % Execute the job
        if strcmpi(params.mode, valsMode{2})
            % Run the progress text wrapper, printing some information text,
            % and saving the results
            progressconsole = ProgressConsole(config);
            fprintf('Running OpenSeqSLAM job');
            if params.batch
                fprintf(' (%s = %d)', j{1}, j{2});
            end
            fprintf(':');
            progressconsole.run();
            fprintf('\n');
            results = progressconsole.results;
        else
            % Run the progress GUI, saving the results
            progressui = ProgressGUI(config);
            progressui.run();
            results = progressui.results;
        end
    end
end
