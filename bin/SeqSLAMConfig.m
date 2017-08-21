function config = SeqSLAMConfig()
    % Default config, relative to toolbox root
    DEFAULT_CONFIG_LOCATION = '.config/default.xml';

    % Open the GUI, load the default config, and waiting until GUI is finished
    iogui = ConfigIOGUI();
    iogui.loadConfigFromXML(fullfile(toolboxRoot(), DEFAULT_CONFIG_LOCATION));
    uiwait(iogui.hFig);
    
    % Save the returned parameters
    config = iogui.config;
end
