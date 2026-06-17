generate_bounds;
bounds = struct(uppers = luts.(upper_name), lowers = luts.(lower_name));

% nums_vel = [20 50 100];
% nums_alt = [20 50 100];
nums_vel = [100];
nums_alt = [100];
name_fmt = "exhaust_%d_by_%d";

if isempty(luts.exhaust_100_by_100)
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
    
            % % display
            % exp_fig = figure(name = target_name);
            % contourf(exhaust_ctrl, cmap = "parula", clabel = "Effort [0-1]");
            % 
            % xlabel(sprintf("Altitude (%d points)", size(exhaust_ctrl, "alt")));
            % xsecondarylabel("m");
            % ylabel(sprintf("Velocity (%d points)", size(exhaust_ctrl, "vel")));
            % ysecondarylabel("m/s");
            % 
            % set(gcf,"Position",[300 300 550 300]);
    
            % print2size(exp_fig, fullfile(graphics_path, target_name + ".pdf"), [500 500]);
    
        end
    end
end

% display
exp_fig = figure(name = "exhaust_100_by_100");
contourf(luts.exhaust_100_by_100, cmap = "parula", clabel = "Effort [0-1]");

my_ylim = ylim;
my_xlim = xlim;

hold on;
plot(altitudes,double(lowers).*(linspace(1.02,1,length(double(lowers)))')-2,"r--","LineWidth",3.5);
plot(altitudes,double(uppers).*(linspace(1,1,length(double(lowers)))')+3,"r--","LineWidth",3.5);

ylim(my_ylim);
xlim(my_xlim);

xlabel(sprintf("Altitude (%d points)", size(luts.exhaust_100_by_100, "alt")));
xsecondarylabel("m");
ylabel(sprintf("Velocity (%d points)", size(luts.exhaust_100_by_100, "vel")));
ysecondarylabel("m/s");

set(gcf, "WindowStyle", "normal");
set(gcf,"Position",[300 100 700 375]);

% nums_quant = [20]
% for i_alt = 1:length(nums_quant)
% 
% end
