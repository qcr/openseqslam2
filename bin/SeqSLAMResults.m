function results = SeqSLAMResults(results, params)
    % Run the results visualisation GUI
    resultsui = ResultsGUI(results, params);
    results = resultsui.results;
end
