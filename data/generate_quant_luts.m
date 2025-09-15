generate_bounds;

% bounds = struct(uppers = luts.(upper_name), lowers = luts.(lower_name));
num_quant = 20;

name_fmt = "quant_%d_by_%d";
target_name = sprintf(name_fmt, num_quant, size(luts.(upper_name), "alt"))

quant_ctrl = calc_quantile_lut(const_simin, apogee_target, ...
    luts.(upper_name), luts.(lower_name), num_quant);
luts.(target_name) = quant_ctrl;

% export to csv
writematrix(["alt" "vel";lower_bounds.("alt") double(lower_bounds)], ...
    lower_name+".csv");
writematrix(["alt" "vel";upper_bounds.("alt") double(upper_bounds)], ...
    upper_name+".csv");
writematrix(["vel_v alt_>" quant_20_by_100.("alt")'; ...
    quant_20_by_100.("quant") double(quant_20_by_100)], target_name+".csv");

% display
exp_fig = figure(name = target_name);
contourf(quant_ctrl, cmap = "parula", clabel = "Effort [0-1]")
xlabel(sprintf("Altitude (%d points)", size(quant_ctrl, "alt")));
xsecondarylabel("m");
ylabel(sprintf("Velocity quantile (%d points)", size(quant_ctrl, "quant")));
ysecondarylabel("m/s");

print2size(exp_fig, fullfile(graphics_path, target_name + ".pdf"), ...
    [500 300]);

