function [results, config] = SeqSLAMResults(results, config)
    % Run the results visualisation GUI, and wait until the GUI finishes
    resultsui = ResultsGUI(results, config);
    uiwait(resultsui.hFig);

    % Return the final results, and the config (which could be adjusted)
    results = resultsui.results;
    config = resultsui.config;
end
