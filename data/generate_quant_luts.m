generate_bounds;

% bounds = struct(uppers = luts.(upper_name), lowers = luts.(lower_name));
num_quant = 20;

name_fmt = "quant_%d_by_%d";
target_name = sprintf(name_fmt, num_quant, size(luts.(upper_name), "alt"))

quant_ctrl = calc_quantile_lut(const_simin, apogee_target, ...
    luts.(upper_name), luts.(lower_name), num_quant);
luts.(target_name) = quant_ctrl;

% export to csv
luts2csv(quant_ctrl, luts.(upper_name), luts.(lower_name), fileparts(luts_file))

% display
exp_fig = figure(name = target_name);
contourf(quant_ctrl, cmap = "parula", clabel = "Effort [0-1]")
xlabel(sprintf("Altitude (%d points)", size(quant_ctrl, "alt")));
xsecondarylabel("m");
ylabel(sprintf("Velocity quantile (%d points)", size(quant_ctrl, "quant")));
ysecondarylabel("m/s");

print2size(exp_fig, fullfile(graphics_path, target_name + ".pdf"), ...
    [500 300]);

