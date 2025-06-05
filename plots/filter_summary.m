clear;
project_globals;
sim_file = pfullfile("sim", "sim_altimeter");
baro_p = baro_params("bmp388");
baro_p.GROUND_LEVEL = doc.sims(1).getOptions().getLaunchAltitude();
filter_p = alt_filter_params("designed");

orkdata = doc.simulate(doc.sims(1), outputs = "ALL");
position = mergevars(orkdata(:, ["Lateral distance", "Altitude"]), ...
    ["Lateral distance", "Altitude"]);

inputs.position = position;
inputs.t_0 = seconds(orkdata.Time(1));
inputs.t_f = seconds(orkdata.Time(end));
inputs.dt = 1/filter_p.input_rate;

simin = structs2inputs(sim_file, inputs);
simin = structs2inputs(simin, baro_p);
simin = structs2inputs(simin, filter_p);

simout = sim(simin);
logs = extractTimetable(simout.logsout);
logs = fillmissing(logs, "previous");

% modify SeriesIndex so that we can plot lines out-of-order to put the true
% orkdata in the middle but keep the default blue-red-yellow color order



flt_figure = figure(name = "Filter performance summary");
layout = tiledlayout(2,2);

true_args = {"DisplayName", "True", "SeriesIndex", 1};
meas_args = {"DisplayName", "Measured", "SeriesIndex", 3, "LineWidth", 0.25};
est_args = {"DisplayName", "Estimated", "SeriesIndex", 2};
lims = seconds([5 16]);

% nexttile; hold on; grid on;
% plot(orkdata.Time, orkdata.("Air pressure"), true_args{:});
% stairs(logs.Time, logs.pressure_meas, meas_args{:});
% legend;

data_ax = nexttile; hold on; grid on;
stairs(logs.Time, logs.altitude_meas, meas_args{:});
plot(orkdata.Time, orkdata.Altitude, true_args{:});
stairs(logs.Time, logs.altitude_est, est_args{:});
ylabel("Altitude");
ysecondarylabel("m AGL");

nexttile; hold on; grid on;
stairs(logs.Time, logs.velocity_meas, meas_args{:});
plot(orkdata.Time, orkdata.("Vertical velocity"), true_args{:});
stairs(logs.Time, logs.velocity_est, est_args{:});
lgn = legend(Orientation = "horizontal");
lgn.Layout.Tile = "north";
xlabel("Time");
ylabel("Vertical velocity");
ysecondarylabel("m/s");

% sync for addition/subtraction
compare_data = synchronize(orkdata, logs, ...
    "regular", "linear", SampleRate = filter_p.output_rate);

compare_ax = nexttile; hold on; grid on;
stairs(compare_data.Time, compare_data.altitude_est - compare_data.("Altitude"));
ylabel("Estimation error");

nexttile; hold on; grid on;
stairs(compare_data.Time, compare_data.velocity_est - compare_data.("Vertical velocity"));
ylabel("Estimation error");
xlabel("Time");

stack_axes(layout);
xlim(data_ax, lims);
xlim(compare_ax, lims);

print2size(flt_figure, "filter_response.pdf", [620 420]);
