function params = make_exhaustive_lut(simin, target, altitudes, velocities, opts)
    arguments
        simin (1,1) Simulink.SimulationInput;
        target (1,1) double;
        altitudes (1,:) double;
        velocities (1,:) double;
        opts.bounds (1,1) struct = struct;
    end
    simin = simin.setVariable(t_0 = 0);
    simin = simin.setModelParameter(SimulationMode = "accelerator", FastRestart = "on");

    [initial_velocities, initial_altitudes] = ndgrid(velocities, altitudes); 
    extensions = zeros(size(initial_altitudes));

    % find upper and lower bounds per altitude to cull search
    if ~isfield(opts.bounds, "uppers") || ~isfield(opts.bounds, "lowers");
        [uppers, lowers] = find_reachable_states(simin, target, altitudes, 0);
        uppers = xarray(uppers, alt = altitudes);
        lowers = xarray(lowers, alt = altitudes);
    else
        uppers = opts.bounds.uppers;
        lowers = opts.bounds.lowers;
    end
    

    for i_sim = 1:numel(extensions)
        start = tic;

        alt = initial_altitudes(i_sim);
        vvel = initial_velocities(i_sim);

        % trivial values for states that can't reach apogee target
        if (vvel >= double(uppers.interp(alt = alt)))
            extensions(i_sim) = 1;
            continue;
        elseif (vvel <= double(lowers.interp(alt = alt)))
            extensions(i_sim) = 0;
            continue;
        end

        % nontrivial values here
        simin = simin.setVariable(position_init = [0; alt]);
        simin = simin.setVariable(velocity_init = [0; vvel]);

        extensions(i_sim) = find_extension(target, simin);
        time = toc(start);

        fprintf("Finished optimization %d of %d in %.2f sec\n", i_sim, numel(extensions), time);
    end

    set_param(simin.ModelName, FastRestart = "off");

    params.lut = xarray(extensions, vel = velocities, alt = altitudes);
end
