
bounds = struct(uppers = uppers, lowers = lowers);
vel_start = 0;
vel_end = 270;
alt_start = 1200;
alt_end = apogee_target;

nums_vel = [20 50 100];
nums_alt = [20 50 100];
name_fmt = "exhaust_%d_by_%d";

for i_alt = 1:length(nums_alt)

    for i_vel = 1:length(nums_vel)
        num_alt = nums_alt(i_alt);
        altitudes = linspace(alt_start, alt_end, num_alt);
        num_vel = nums_vel(i_vel);
        velocities = linspace(vel_start, vel_end, num_vel);
        target_name = sprintf(name_fmt, num_vel, num_alt);

        exhaust_ctrl = make_exhaustive_lut(const_simin, apogee_target, altitudes, velocities, ...
            bounds = bounds);

        cache.(target_name) = exhaust_ctrl;

        figure(name = target_name);
        imagesc(exhaust_ctrl.lut);
        drawnow;

        luts.(target_name) = exhaust_ctrl;
    end
end
