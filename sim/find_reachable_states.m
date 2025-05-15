function [uppers, lowers] = find_reachable_states(simin, target, altitudes, initial_hvel, opts)
    arguments
        simin Simulink.SimulationInput
        target (1,1) double;
        altitudes (1,:) double;
        initial_hvel (1,1) double;
        opts.vvel_guess (1,1) double = 500;
        opts.close_enough (1,1) double = 1;
    end

    % flow:
    % - baseline simulation establishes altitude/horizontal velocity
    %   relationship during ascent
    % - subsequent simulations initialize with the baseline simulation's
    %   horizontal velocity at that altitude, then root-find on the vertical velocity to hit the target

    stop_close_enough = @(~, values, state) (state == "iter") && (abs(values.fval) <= opts.close_enough);
    fzero_opts = optimset(Display = "none", OutputFcn = stop_close_enough);

    % baseline simulation to establish vertical/horizontal velocity relationship
    simin = simin.setVariable(position_init = [0; altitudes(1)]);
    simin = simin.setVariable(const_brake = 0);
    hvel = initial_hvel;
    baseline_vvel = fzero(@zmaxfunc, opts.vvel_guess, fzero_opts);
    [~, baseline_out] = zmaxfunc(baseline_vvel); % re-run to get full output
    baseline_out = extractTimetable(baseline_out.logsout);
    hvels = interp1(baseline_out.position(1:end-1, 2), baseline_out.velocity(1:end-1,1), altitudes, "linear", NaN);
    if any(isnan(hvels))
        error("Some altitude inputs are out-of-bounds.");
    end

    uppers = NaN(size(altitudes));   
    lowers = NaN(size(altitudes));   

    for i_alt = 1:length(altitudes)
        simin = simin.setVariable(position_init = [0; altitudes(i_alt)]);
        % quick optimization to have better initial guesses, saving some model evaluations
        % strictly optional though
        if i_alt == 1
            upper_guess = opts.vvel_guess;
            lower_guess = opts.vvel_guess;
        else
            upper_guess = uppers(i_alt-1);
            lower_guess = lowers(i_alt-1);
        end

        hvel = hvels(i_alt);
        uppers(i_alt) = fzero(@zmaxfunc, upper_guess, fzero_opts);
        lowers(i_alt) = fzero(@zminfunc, lower_guess, fzero_opts);
        fprintf("Finished altitude %d of %d\n", i_alt, length(altitudes));
    end

    
    % functions to root-find on - when they are zero, the vertical velocity to
    % reach the target is minimized (maximized)
    %
    % uses "global" knowledge of simin, hvel, and vvel
    % kind of dirty but the other option is two more nested functions, which is harder to understand
    % second output to get full simulation output when needed

    function [err, so] = zminfunc(vvel)
        simin = simin.setVariable(velocity_init = [hvel; vvel]);
        simin = simin.setVariable(const_brake = 0);

        so = sim(simin);

        err = so.apogee - target;
    end

    function [err, so] = zmaxfunc(vvel)
        simin = simin.setVariable(velocity_init = [hvel; vvel]);
        simin = simin.setVariable(const_brake = 1);

        so = sim(simin);

        err = so.apogee - target;
    end
end
