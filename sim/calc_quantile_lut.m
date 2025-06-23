function lut = calc_quantile_lut(simin, target, upper_bounds, lower_bounds, num_velocities)
    arguments (Input)
        simin  (1,1) Simulink.SimulationInput
        target (1,1) double;
        upper_bounds (:,1) xarray {mustHaveAxes(upper_bounds, ["alt"])};
        lower_bounds (:,1) xarray {mustHaveAxes(lower_bounds, ["alt"])};;
        num_velocities (1,1) double;
    end
    arguments (Output)
        lut (:,:) xarray {mustHaveAxes(lut, ["quant", "alt"])};
    end

    altitudes = upper_bounds.alt;
    quantiles = linspace(0, 1, num_velocities);
    simin = simin.setVariable(t_0 = 0);
    simin = simin.setModelParameter(SimulationMode = "accelerator", FastRestart = "on");

    lut = xarray(NaN(length(quantiles), length(altitudes)), ...
        quant = quantiles, alt = altitudes);

    for i_alt = 1:length(altitudes)
        alt = altitudes(i_alt);
        lower = lower_bounds{i_alt};
        upper = upper_bounds{i_alt};
        simin = simin.setVariable(position_init = [0; alt]);

        for i_quant = 1:length(quantiles)
            start = tic;
            vvel = lower + (upper - lower) * quantiles(i_quant);

            simin = simin.setVariable(velocity_init = [0; vvel]);

            lut.index{"alt", i_alt, "quant", i_quant} = calc_extension(target, simin);

            fprintf("Finished optimization %d of %d in %.2f sec\n", ...
                sub2ind(size(lut), i_quant, i_alt), numel(lut), toc(start));

        end
    end

    set_param(simin.ModelName, FastRestart = "off");
end
