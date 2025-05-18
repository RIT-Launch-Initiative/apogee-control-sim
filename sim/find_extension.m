function ext = find_extension(target, simin)
    % set up optimization
    tol = 1; % [m]
    iters_left = 100;
    err = Inf;
    
    % execute optimization
    si = simin.setVariable(const_brake = 0);
    so = sim(si);
    upper_bound = so.apogee;
    if upper_bound <= target
        ext = 0;
        return;
    end
    si = simin.setVariable(const_brake = 1);
    so = sim(si);
    lower_bound = so.apogee;
    if lower_bound >= target
        ext = 1;
        return;
    end
    
    rang = upper_bound - lower_bound;
    ext = (target - lower_bound) / rang;
    while (abs(err) > tol) && (iters_left > 0)
        iters_left = iters_left - 1;

        si = simin.setVariable(const_brake = ext);
        so = sim(si);
        err = so.apogee - target;
        ext = ext + err / rang;
    end
    if iters_left == 0
        warning("Iteration failed to converge");
    end

end
