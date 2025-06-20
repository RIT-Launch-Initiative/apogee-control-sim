bounds = struct(uppers = uppers, lowers = lowers);

nums_vel = [20 50 100];
nums_alt = [20 50 100];
name_fmt = "exhaust_%d_by_%d";

for i_alt = 1:length(nums_alt)

    for i_vel = 1:length(nums_vel)
        num_alt = nums_alt(i_alt);
        altitudes = linspace(alt_start, apogee_target, num_alt);
        num_vel = nums_vel(i_vel);
        velocities = linspace(0, vel_max, num_vel);
        target_name = sprintf(name_fmt, num_vel, num_alt);

        exhaust_ctrl = calc_exhaustive_lut(const_simin, apogee_target, altitudes, velocities, ...
            bounds = bounds);

        cache.(target_name) = exhaust_ctrl;

        figure(name = target_name);
        imagesc(exhaust_ctrl.lut);
        drawnow;

        luts.(target_name) = exhaust_ctrl;
    end
end
