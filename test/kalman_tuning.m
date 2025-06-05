clear;
project_globals;

alt_p = baro_params("bmp388");
accel_p = accel_params("lsm6dsl");
accel_p.GRAVITY = 9.81;
kalm_p = kalman_filter_params("accel-bias");

kalm_p.kalm_meas_cov = diag([100, 8e-4]);
kalm_p.kalm_process_cov = diag([0.01 0.01 20 1]);

orksim = doc.sims("MATLAB");
simopts = orksim.getOptions();

alt_p.GROUND_LEVEL = simopts.getLaunchAltitude();

orkdata = doc.simulate(orksim, outputs = "ALL", stop = "APOGEE");
orkdata = fillmissing(orkdata, "previous");

inputs.t_0 = seconds(orkdata.Time(1));
inputs.t_f = seconds(orkdata.Time(end));
inputs.dt = 1/kalm_p.input_rate;

inputs.position = timeseries(orkdata{:, ["Lateral distance", "Altitude"]}, ...
    seconds(orkdata.Time));
inputs.accel_fixed = timeseries(orkdata{:, ["Lateral acceleration", "Vertical acceleration"]}, ...
    seconds(orkdata.Time));
inputs.pitch = orkdata(:, "Vertical orientation (zenith)");

simin = structs2inputs("sim_estimator", kalm_p);
simin = structs2inputs(simin, alt_p);
simin = structs2inputs(simin, accel_p);
simin = structs2inputs(simin, inputs);

simout = sim(simin);
logs = extractTimetable(simout.logsout);
logs = fillmissing(logs, "previous");
compare_data = synchronize(orkdata, logs, "regular", "linear", SampleRate = kalm_p.output_rate);

true_args = {"DisplayName", "True"};
meas_args = {"DisplayName", "Measured"};
est_args = {"DisplayName", "Estimated"};

figure;
layout = tiledlayout(3,2);
layout.TileIndexing = "rowmajor";

nexttile; hold on; grid on;
plot(orkdata.Time, orkdata.Altitude, true_args{:});
plot(logs.Time, logs.altitude_meas, meas_args{:});
plot(logs.Time, logs.altitude_est, est_args{:});

nexttile; hold on; grid on;
plot(compare_data.Time, compare_data.altitude_est - compare_data.altitude_meas);

nexttile; hold on; grid on;
plot(orkdata.Time, orkdata.("Vertical velocity"), true_args{:})
plot(logs.Time, logs.velocity_meas, meas_args{:});
plot(logs.Time, logs.velocity_est, est_args{:});

nexttile; hold on; grid on;
plot(compare_data.Time, compare_data.velocity_est - compare_data.("Vertical velocity"));

nexttile; hold on; grid on;
plot(orkdata.Time, orkdata.("Vertical acceleration"), true_args{:})
plot(logs.Time, logs.accel_meas, meas_args{:});
plot(logs.Time, logs.accel_est, est_args{:});
plot(logs.Time, logs.accel_bias_est, "--", DisplayName = "Bias");

nexttile; hold on; grid on;
plot(compare_data.Time, compare_data.accel_est - compare_data.("Vertical acceleration"));
