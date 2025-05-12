function ext = find_extension(target, simin, guess)
    % de-initialize model so we can make changes 
    set_param(simin.ModelName, FastRestart = "off");
    % accelerator mode generates a "simulation target" that runs faster
    simin = simin.setModelParameter(SimulationMode = "accelerator");
    % use FastRestart to prevent model recompilation
    simin = simin.setModelParameter(FastRestart = "on");
    simin = simin.setVariable(control_mode = "const");
    

    % set up optimization
    apogee_tolerance = 1; % [m] terminate when error falls below this value
    stop_tolerance = @(~, values, ~) values.fval <= apogee_tolerance;
    simin = struct2input(simin, struct("control_brake", false));
    % Dispay=none shuts up "optimization terminated early"
    opts = optimset(OutputFcn = stop_tolerance, Display = "none"); 
    
    % execute optimization
    ext = fminsearch(@costfunc, guess, opts);

    % de-initialize model so we can make changes 
    set_param(simin.ModelName, FastRestart = "off");

    function cost = costfunc(ext)
        ext = clip(ext, 0, 1);
        si = simin.setVariable(const_brake = ext);
        so = sim(si);
        % use Dataset's getElement so we don't incur expense of converting to timetable
        cost = abs(target - so.apogee);
    end
end
