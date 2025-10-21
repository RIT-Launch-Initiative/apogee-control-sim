generate_bounds;
bounds = struct(uppers = luts.(upper_name), lowers = luts.(lower_name));

% nums_vel = [20 50 100];
% nums_alt = [20 50 100];
nums_vel = [100];
nums_alt = [100];
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

        luts.(target_name) = exhaust_ctrl;

        % display
        exp_fig = figure(name = target_name);
        contourf(exhaust_ctrl, cmap = "parula", clabel = "Effort [0-1]");

        xlabel(sprintf("Altitude (%d points)", size(exhaust_ctrl, "alt")));
        xsecondarylabel("m");
        ylabel(sprintf("Velocity (%d points)", size(exhaust_ctrl, "vel")));
        ysecondarylabel("m/s");

        % print2size(exp_fig, fullfile(graphics_path, target_name + ".pdf"), [500 500]);

    end
end

% nums_quant = [20]
% for i_alt = 1:length(nums_quant)
% 
% end
