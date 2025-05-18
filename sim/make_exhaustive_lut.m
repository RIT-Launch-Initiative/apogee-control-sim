function params = make_exhaustive_lut(simin, target, altitudes, velocities)
    simin = simin.setVariable(t_0 = 0);
    simin = simin.setModelParameter(SimulationMode = "accelerator", FastRestart = "on");

    [initial_velocities, initial_altitudes] = ndgrid(velocities, altitudes); 
    extensions = zeros(size(initial_altitudes));

    % find upper and lower bounds per altitude to 
    [uppers, lowers] = find_reachable_states(simin, target, altitudes, 0);

    for i_sim = 1:numel(extensions)
        start = tic;

        alt = initial_altitudes(i_sim);
        vvel = initial_velocities(i_sim);
        % default values for states that can't reach apogee target
        % use (altitude == alt) instead of i_sim because uppers() and lowers() are 1xN_alt rows
        if (vvel >= uppers(altitudes == alt))
            extensions(i_sim) = 1;
            continue;
        elseif (vvel <= lowers(altitudes == alt))
            extensions(i_sim) = 0;
            continue;
        end

        simin = simin.setVariable(position_init = [0; alt]);
        simin = simin.setVariable(velocity_init = [0; vvel]);

        extensions(i_sim) = find_extension(target, simin);
        time = toc(start);

        fprintf("Finished optimization %d of %d in %.2f sec\n", i_sim, numel(extensions), time);
    end

    set_param(simin.ModelName, FastRestart = "off");

    params.lut = xarray(extensions, vel = velocities, alt = altitudes);
end
