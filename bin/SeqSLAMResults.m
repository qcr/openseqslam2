function results = SeqSLAMResults(results, params)
    % Run the results visualisation GUI, and wait until the GUI finishes
    resultsui = ResultsGUI(results, params);
    uiwait(resultsui.hFig);

    % Return the final results
    %results = resultsui.results;
    results = resultsui;
end
