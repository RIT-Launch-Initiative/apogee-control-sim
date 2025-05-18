function params = make_quantile_lut(simin, target, altitudes, num_velocities)
    quantiles = linspace(0, 1, num_velocities);
    simin = simin.setVariable(t_0 = 0);
    simin = simin.setModelParameter(SimulationMode = "accelerator", FastRestart = "on");

    extensions = zeros(num_velocities, length(altitudes));

    % find upper and lower bounds per altitude to 
    [uppers, lowers] = find_reachable_states(simin, target, altitudes, 0);

    for i_alt = 1:length(altitudes)
        alt = altitudes(i_alt);
        lower = lowers(i_alt);
        upper = uppers(i_alt);

        simin = simin.setVariable(position_init = [0; alt]);
        for i_quant = 1:num_velocities
            start = tic;

            vvel = lower + (upper - lower) * quantiles(i_quant);
            simin = simin.setVariable(velocity_init = [0; vvel]);
            extensions(i_quant, i_alt) = find_extension(target, simin);

            time = toc(start);
            fprintf("Finished optimization %d of %d in %.2f sec\n", ...
                i_quant + (i_alt - 1) * num_velocities, length(altitudes) * num_velocities, time);
        end
    end

    set_param(simin.ModelName, FastRestart = "off");

    params.upper_bound_lut = xarray(uppers, alt = altitudes);
    params.lower_bound_lut = xarray(lowers, alt = altitudes);
    params.quantile_lut = xarray(extensions, quant = quantiles, alt = altitudes);
end
