function ext = find_extension(target, simin, guess)
    % set up optimization
    simin = simin.setVariable(control_mode = "const");
    opts = optimset(Display = "none", TolX = 1e-3); 
    
    % execute optimization
    if errfunc(0) <= 0 % no point running if we can't hit apogee target as-is
        ext = 0;
    elseif errfunc(1) >= 0 % no point running if we can't hit apogee target as-is
        ext = 1;
    else
        % a bit faster than fminsearch since this problem is 1D
        ext = fzero(@errfunc, guess, opts);
    end

    function [error] = errfunc(ext)
        ext = clip(ext, 0, 1);
        si = simin.setVariable(const_brake = ext);
        so = sim(si);
        error = so.apogee - target;
    end
end
