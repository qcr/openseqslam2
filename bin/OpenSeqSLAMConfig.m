function config = OpenSeqSLAMConfig()
    % Default config, relative to toolbox root
    DEFAULT_CONFIG_LOCATION = '.config/default.xml';

    % Open the GUI, load the default config, and waiting until GUI is finished
    iogui = ConfigIOGUI();
    iogui.loadConfigFromXML(fullfile(toolboxRoot(), DEFAULT_CONFIG_LOCATION));
    uiwait(iogui.hFig);

    % Save the returned parameters if the ui safely completed
    if iogui.done
        config = iogui.config;
    else
        config = [];
    end
end
