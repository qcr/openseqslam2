function [results, config] = OpenSeqSLAMResults(results, config)
    % Completely separate execution path, depending on whether the results are
    % for batch, or single
    if isscalar(results)
        % Run the results visualisation GUI, and wait until the GUI finishes
        resultsui = ResultsGUI(results, config);
        uiwait(resultsui.hFig);

        % Return the final results, and the config (which could be adjusted)
        results = resultsui.results;
        config = resultsui.config;
    else
        % Run the batch results visualisation GUI, and wait until done
        % TODO
        uiwait(resultsui.hFig);

        % Return the final batch results, and the config (which should not have
        % been modified)
        results = resultsui.results;
        config = resultsui.config;
    end
end
