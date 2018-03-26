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

        % Clean out the root results directory here
        cleanDir(config.results.path);
    else
        jobs = {{}};
    end

    % Create the batch mode UI if necessary
    batchui = [];
    if params.batch && strcmpi(params.mode, valsMode{1})
        batchui = BatchPopup(length(jobs));
    end

    % Start running through each of the jobs
    diffs = cell(1, length(jobs));
    match = cell(1, length(jobs));
    parfor k = 1:length(jobs)
        % Do any required pre-processing for the job
        j = jobs{k};
        c = config;
        if ~isempty(j)
            c = setDeepField(c, j{1}, j{2});
            s1 = strsplit(j{1}, '.');
            s2 = strrep(num2str(j{2}), '.', '_');
            c.results.path = fullfile(config.results.path, [s1{end} '-' s2]);
        end

        % Execute the job
        if strcmpi(params.mode, valsMode{2})
            % Run the progress text wrapper, printing some information text,
            % and saving the results
            progressconsole = ProgressConsole(c);
            fprintf('Running OpenSeqSLAM job');
            if params.batch
                fprintf(' (%s = %s)', j{1}, num2str(j{2}));
            end
            fprintf(':');
            progressconsole.run();
            fprintf('\n');
            r = progressconsole.results;
        else
            % % Run the progress GUI, saving the results
            % progressui = ProgressGUI(c);

            % % Update batch UI if necessary
            % if ~isempty(batchui)
            %     batchui.updateJob(j, k);
            %     batchui.hFig.WindowStyle = 'modal';
            % end

            % progressui.run();
            % r = progressui.results;
        end

        % Store the results only save the useful parts for batch mode
        if params.batch
            % results.tests(k).diff_matrix = r.diff_matrix;
            % results.tests(k).matching = r.matching;
            diffs{k} = r.diff_matrix;
            match{k} = r.matching;
        else
            % results = r;
        end
    end

    % TODO remove
    for k = 1:length(jobs)
        results.tests(k).diff_matrix = diffs{k};
        results.tests(k).matching = match{k};
    end

    % Close the batch mode UI if necessary
    if params.batch && strcmpi(params.mode, valsMode{1})
        close(batchui.hFig);
    end
end
