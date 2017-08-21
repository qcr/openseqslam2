function [params, dbg] = SeqSLAMConfig()
    % Open the GUI, waiting until it is finished
    dbg = ConfigIOGUI();
    
    % Save the returned parameters
    params = dbg.params;
end
