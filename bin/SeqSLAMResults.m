function [results, dbg] = SeqSLAMResults(results, params)
    % Run the results visualisation GUI
    dbg = ResultsGUI(results, params);

end
