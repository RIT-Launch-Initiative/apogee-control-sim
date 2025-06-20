clear; 
project_globals;

% get raw data from OpenRocket
% orkopts.setWindSpeedDeviation(0);
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
baro_p.position = orkdata(:, "position");
baro_p.position_init = orkdata{1, "position"}';
baro_p.velocity_init = orkdata{1, ["Lateral velocity", "Vertical velocity"]}';
alt_filter = alt_filter_params("none");

baro_simin = structs2inputs(pfullfile("sim", "sim_altimeter"), config);
baro_simin = structs2inputs(baro_simin, baro_p);
baro_simin = structs2inputs(baro_simin, alt_filter);
baro_simout = sim(baro_simin);
baro_logs = extractTimetable(baro_simout.logsout);

% SeriesIndex uses the appropriate part of the default plot coloring order
true_args = {"DisplayName", "True", "SeriesIndex", 1};
meas_args = {"DisplayName", "Measured", "SeriesIndex", 2};

alt_fig = figure(name = "Altimeter impairments");
layout = tiledlayout("vertical");
layout.TileSpacing = "tight";

nexttile; hold on; grid on;
plot(baro_logs.Time, baro_logs.altitude_est, meas_args{:});
plot(orkdata.Time, orkdata.position(:, 2), true_args{:});
legend(Location = "north", Orientation = "horizontal");
ylabel("Altitude");
ysecondarylabel("m AGL");

nexttile; hold on; grid on;
plot(baro_logs.Time, baro_logs.velocity_est, meas_args{:});
plot(orkdata.Time, orkdata.("Vertical velocity"), true_args{:});
ylabel("Vertical velocity");
ysecondarylabel("m/s");

linkaxes(layout.Children, "x");
xlabel(layout, "Time");
xlim(seconds([5 7]));

print2size(alt_fig, fullfile(graphics_path, "altitude_noise.pdf"), [500 400]);

accel_p = accel_params("lsm6dsl");
accel_p.accel = orkdata(:, "accel_fixed");
accel_p.pitch = orkdata(:, "Vertical orientation (zenith)");
accel_filter = accel_filter_params("none");

accel_simin = structs2inputs(pfullfile("sim", "sim_accelerometer"), config);
accel_simin = structs2inputs(accel_simin, accel_p);
accel_simin = structs2inputs(accel_simin, accel_filter);
accel_simout = sim(accel_simin);
accel_logs = extractTimetable(accel_simout.logsout);


accel_fig = figure(name = "Accelerometer impairments");
layout = tiledlayout("vertical");
layout.TileSpacing = "tight";

nexttile; hold on; grid on;
plot(accel_logs.Time, accel_logs.accel_est, meas_args{:});
plot(orkdata.Time, orkdata.accel_fixed(:, 2), true_args{:});
legend(Location = "best");

nexttile; hold on; grid on;
compare_data = synchronize(orkdata, accel_logs, "regular", "linear", ...
    SampleRate = accel_logs.Properties.SampleRate);
plot(compare_data.Time, compare_data.accel_est - compare_data.accel_fixed(:,2), ...
    DisplayName = "Difference");
plot(compare_data.Time, compare_data.("Gravitational acceleration"), ...
    DisplayName = "Gravity");
legend(Location = "best");

linkaxes(layout.Children, "x");
xlabel(layout, "Time");

print2size(alt_fig, fullfile(graphics_path, "accel_noise.pdf"), [500 400]);
