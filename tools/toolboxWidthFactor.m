function f = toolboxWidthFactor()
    if isunix()
        f = 1.0;
    elseif ispc()
        f = 1.1;
    elseif ismac()
        f = 1.0;
    end
end
