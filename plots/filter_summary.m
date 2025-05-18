clear;
project_globals;
sim_file = pfullfile("sim", "sim_altimeter");
params = get_brake_data("noisy");
params.GROUND_LEVEL = doc.sims(1).getOptions().getLaunchAltitude();


data = doc.simulate(doc.sims(1), outputs = "ALL");
position = data(:, ["Lateral distance", "Altitude"]);
position = mergevars(position, ["Lateral distance", "Altitude"]);

params.t_0 = seconds(data.Time(1));
params.t_f = seconds(data.Time(end));
params.dt = 1/params.observer_rate;

simin = structs2inputs(sim_file, params);

simout = sim(simin);
logs = extractTimetable(simout.logsout);
logs = fillmissing(logs, "previous");

% modify SeriesIndex so that we can plot lines out-of-order to put the true
% data in the middle but keep the default blue-red-yellow color order



flt_figure = figure(name = "Filter performance summary");
layout = tiledlayout(2,2);

true_args = {"DisplayName", "True", "SeriesIndex", 1};
meas_args = {"DisplayName", "Measured", "SeriesIndex", 3, "LineWidth", 0.25};
est_args = {"DisplayName", "Estimated", "SeriesIndex", 2};
lims = seconds([5 16]);

% nexttile; hold on; grid on;
% plot(data.Time, data.("Air pressure"), true_args{:});
% stairs(logs.Time, logs.pressure_meas, meas_args{:});
% legend;

data_ax = nexttile; hold on; grid on;
stairs(logs.Time, logs.altitude_meas, meas_args{:});
plot(data.Time, data.Altitude, true_args{:});
stairs(logs.Time, logs.altitude_est, est_args{:});
ylabel("Altitude");
ysecondarylabel("m AGL");

nexttile; hold on; grid on;
stairs(logs.Time, logs.velocity_meas, meas_args{:});
plot(data.Time, data.("Vertical velocity"), true_args{:});
stairs(logs.Time, logs.velocity_est, est_args{:});
lgn = legend(Orientation = "horizontal");
lgn.Layout.Tile = "north";
xlabel("Time");
ylabel("Vertical velocity");
ysecondarylabel("m/s");

% sync for addition/subtraction
compare_data = synchronize(data, logs, ...
    "regular", "linear", SampleRate = params.observer_rate);

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

export_at_size(flt_figure, "filter_response.pdf", [620 420]);
