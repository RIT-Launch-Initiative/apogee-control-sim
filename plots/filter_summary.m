clear;
project_globals;

% roi = timerange(seconds(5.2), seconds(12.5));
roi = timerange(seconds(-Inf), seconds(Inf));

alt_path = pfullfile("sim", "sim_altimeter");
kalm_path = pfullfile("sim", "sim_kalman");

% get raw data from OpenRocket
% orkopts.setWindSpeedDeviation(0);
% orkopts.setLaunchRodAngle(deg2rad(20));
orkdata = doc.simulate(orksim, stop = "APOGEE", outputs = "ALL");
% join to N-by-2 for Simulink input
orkdata = mergevars(orkdata, ["Lateral acceleration", "Vertical acceleration"], ...
    NewVariableName = "accel_fixed");
orkdata = mergevars(orkdata, ["Lateral distance", "Altitude"], ...
    NewVariableName = "position");

config.t_0 = seconds(orkdata.Time(1));
config.t_f = seconds(orkdata.Time(end));
config.dt = 1/100;
config.GROUND_LEVEL = orkopts.getLaunchAltitude();
config.GRAVITY = orkdata{1, "Gravitational acceleration"};

baro_p = baro_params("bmp388");
accel_p = accel_params("lsm6dsl");
inputs.position = orkdata(:, "position");
inputs.position_init = orkdata{1, "position"}';
inputs.velocity_init = orkdata{1, ["Lateral velocity", "Vertical velocity"]}';
inputs.accel = orkdata(:, "accel_fixed");
inputs.pitch = orkdata(:, "Vertical orientation (zenith)");

simin_lowpass = structs2inputs(alt_path, ...
    config, inputs, baro_p, alt_filter_params("designed"));

simin_kalm_bias = structs2inputs(kalm_path, ...
    config, inputs, baro_p, accel_p, kalman_filter_params("alt-accel-bias"));

simin_kalm_accel = structs2inputs(kalm_path, ...
    config, inputs, baro_p, accel_p, kalman_filter_params("alt-accel"));

simin_kalm_alt = structs2inputs(kalm_path, ...
    config, inputs, baro_p, accel_p, kalman_filter_params("alt"));

filters(1).simin = simin_lowpass;
filters(1).label = "Low-pass";

filters(2).simin = simin_kalm_alt;
filters(2).label = "Kalman (alt only)";

filters(3).simin = simin_kalm_accel;
filters(3).label = "Kalman (alt+accel)";

filters(4).simin = simin_kalm_bias;
filters(4).label = "Kalman (alt+accel+bias)";

filters_fig = figure(name = "Estimator errors");
layout = tiledlayout("vertical");
layout.TileSpacing = "tight";

alt_ax = nexttile; hold on; grid on;
yline(0, "-k", HandleVisibility = "off");
legend;
ylabel("Altitude error");
ysecondarylabel("m");

vel_ax = nexttile; hold on; grid on;
yline(0, "-k", HandleVisibility = "off");
legend;
ylabel("Velocity error");
ysecondarylabel("m/s");


for i_filter = 1:length(filters)
    simout = sim(filters(i_filter).simin);
    logs = extractTimetable(simout.logsout);
    compare = synchronize(orkdata, logs, "regular", "linear", ...
        SampleRate = logs.Properties.SampleRate);
    compare = compare(roi, :);
    
    compare.alt_err = compare.altitude_est - compare.position(:,2);
        alt_label = sprintf("%s: \\mu = %+.2f m | \\sigma = %.2f m", ...
        filters(i_filter).label, mean(compare.alt_err), std(compare.alt_err));
    compare.vel_err = compare.velocity_est - compare.("Vertical velocity");
    vel_label = sprintf("%s: \\mu = %+.2f m/s | \\sigma = %.2f m/s", ...
        filters(i_filter).label, mean(compare.vel_err), std(compare.vel_err));

    plot(alt_ax, compare.Time, compare.alt_err, DisplayName = alt_label, SeriesIndex = i_filter);
    plot(vel_ax, compare.Time, compare.vel_err, DisplayName = vel_label, SeriesIndex = i_filter);
end

alt_range = max(alt_ax.YLim, [], ComparisonMethod = "abs");
alt_ax.YLim = abs(alt_range) * [-1 1];
vel_range = max(vel_ax.YLim, [], ComparisonMethod = "abs");
vel_ax.YLim = abs(vel_range) * [-1 1];

linkaxes(layout.Children, "x");
xlabel(layout, "Time");

out_name = sprintf("estimator_responses_%d.pdf", rad2deg(orkopts.getLaunchRodAngle()));
% print2size(filters_fig, fullfile(graphics_path, out_name), [800 600]);
