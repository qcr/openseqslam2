function config = OpenSeqSLAMConfig()
    % Open the GUI, load the default config, and waiting until GUI is finished
    iogui = ConfigIOGUI();
    iogui.loadConfigFromXML(fullfile(toolboxRoot(), '.config', 'default.xml'));
    uiwait(iogui.hFig);

    % Save the returned parameters if the ui safely completed
    if iogui.done
        config = iogui.config;
    else
        config = [];
    end
end
