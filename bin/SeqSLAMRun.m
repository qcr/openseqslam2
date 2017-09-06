function results = SeqSLAMRun(config)
    % Create the progress GUI
    ioprogress = ProgressGUI(config);

    % Run the SeqSLAM instance until done
    ioprogress.run();

    % Save the results
    results = ioprogress.results;
end
