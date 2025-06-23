function lut = calc_exhaustive_lut(simin, target, altitudes, velocities, opts)
    arguments (Input)
        simin (1,1) Simulink.SimulationInput;
        target (1,1) double;
        altitudes (1,:) double;
        velocities (1,:) double;
        opts.bounds (1,1) struct = struct;
    end
    arguments (Output)
        lut (:, :) xarray {mustHaveAxes(lut, ["vel", "alt"])};
    end
    simin = simin.setVariable(t_0 = 0);
    simin = simin.setModelParameter(SimulationMode = "accelerator", FastRestart = "on");

    [initial_velocities, initial_altitudes] = ndgrid(velocities, altitudes); 
    lut = xarray(NaN(length(velocities), length(altitudes)), ...
        vel = velocities, alt = altitudes);

    % find upper and lower bounds per altitude to cull search
    if ~isfield(opts.bounds, "uppers") || ~isfield(opts.bounds, "lowers");
        [uppers, lowers] = calc_bounds(simin, target, altitudes, 0);
        uppers = xarray(uppers, alt = altitudes);
        lowers = xarray(lowers, alt = altitudes);
    else
        uppers = opts.bounds.uppers;
        lowers = opts.bounds.lowers;
    end

    for i_alt = 1:length(altitudes)
        alt = altitudes(i_alt);
        simin = simin.setVariable(position_init = [0; alt]);

        for i_vel = 1:length(velocities)
            vel = velocities(i_vel);
            % trivial values for states that can't reach apogee target
            if (vel >= double(uppers.interp(alt = alt)))
                ext = 1;
            elseif (vel <= double(lowers.interp(alt = alt)))
                ext = 0;
            else % nontrivial case
                start = tic;

                simin = simin.setVariable(velocity_init = [0; vel]);
                ext = calc_extension(target, simin);

                fprintf("Finished optimization %d of %d in %.2f sec\n", ...
                    sub2ind(size(lut), i_vel, i_alt), numel(lut), toc(start));
            end
            lut.index{"alt", i_alt, "vel", i_vel} = ext;
        end
    end

    set_param(simin.ModelName, FastRestart = "off");
end
