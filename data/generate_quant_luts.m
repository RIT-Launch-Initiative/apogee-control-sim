generate_bounds;

% bounds = struct(uppers = luts.(upper_name), lowers = luts.(lower_name));
num_quant = 20;

name_fmt = "quant_%d_by_%d";
target_name = sprintf(name_fmt, num_quant, size(luts.(upper_name), "alt"));

if isempty(luts.quant_20_by_100)

    quant_ctrl = calc_quantile_lut(const_simin, apogee_target, ...
        luts.(upper_name), luts.(lower_name), num_quant);
    luts.(target_name) = quant_ctrl;

end

% export luts and info for avi (change the location of this)
% luts2csv(luts.(upper_name), luts.(lower_name), fileparts(luts_file));
% luts2json(luts.(upper_name), luts.(lower_name), airdata, fileparts(luts_file));

% display
exp_fig = figure(name = target_name);
contourf(luts.quant_20_by_100, cmap = "parula", clabel = "Effort [0-1]")
xlabel(sprintf("Altitude (%d points)", size(luts.quant_20_by_100, "alt")));
xsecondarylabel("m");
ylabel(sprintf("Velocity quantile (%d points)", size(luts.quant_20_by_100, "quant")));
ysecondarylabel("m/s");

yline([0 1]+0.014.*[1 -1],"r--","LineWidth",6)

set(gcf, "WindowStyle", "normal");
set(gcf,"Position",[300 100 700 375]);

% print2size(gcf,pfullfile("QLUT.pdf"),[700 375], "pixels");

% print2size(exp_fig, fullfile(graphics_path, target_name + ".pdf"), [500 300]);

