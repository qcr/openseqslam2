function dbg = SeqSLAM(varargin)
    % Add the toolbox to the path
    run(fullfile(fileparts(which('SeqSLAM')), 'tools', 'toolboxInit'));

    % Add the option to just load defaults and run
    if length(varargin) > 0 && varargin{1}
        config = xml2settings('.config/default.xml');
    else
        % Run the config GUI to set all required parameters
        config = SeqSLAMConfig();
        % Abort if no parameters are returned
        if isempty(config)
            fprintf('Exited start dialog. Aborting...\n');
            db= [];
            return;
        end
    end

    % Run the SeqSLAM process, and get the results
    results = SeqSLAMRun(config);

    % Run the results visualisation GUI
    dbg = SeqSLAMResults(results, config);
end
