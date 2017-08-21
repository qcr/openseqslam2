function SeqSLAM()
    % Add the toolbox to the path
    run(fullfile(fileparts(which('SeqSLAM')), 'tools', 'toolboxInit'));

    % Run the config GUI to set all required parameters
    config = SeqSLAMConfig();
    return;
    % Abort if no parameters are returned
    if isempty(config)
        fprintf('Exited start dialog. Aborting...\n');
        return;
    end

    % Run SeqSLAM with the parameters
    results = openSeqSLAM(config);

    % Run the results visualisation GUI
    dbg = SeqSLAMResults(results, config);
end
