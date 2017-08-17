function SeqSLAM()
    % Run the config GUI to set all required parameters
    params = SeqSLAMConfig();

    % Abort if no parameters are returned
    if isempty(params)
        fprintf('Exited start dialog. Aborting...\n');
        return;
    end

    % Run SeqSLAM with the parameters
    results = openSeqSLAM(params);

    % Run the results visualisation GUI
    dbg = SeqSLAMResults(results, params);
end
