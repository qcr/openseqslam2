function [results, config] = OpenSeqSLAM2(varargin)
    % Add the toolbox to the path
    run(fullfile(fileparts(which('OpenSeqSLAM2')), 'tools', 'toolboxInit'));

    % Add the option to just load defaults and run
    if length(varargin) > 0 && varargin{1}
        config = xml2settings( ...
            fullfile(toolboxRoot(), '.config', 'default.xml'));
    else
        % Run the config GUI to set all required parameters
        config = OpenSeqSLAMConfig();

        % Abort if no parameters are returned
        if isempty(config)
            fprintf('Exited start dialog. Aborting...\n');
            results = [];
            return;
        end
    end

    % Run the SeqSLAM process, and get the results
    results = OpenSeqSLAMRun(config);

    % Run the results visualisation GUI
    [results, config] = OpenSeqSLAMResults(results, config);
end
