clear;
project_globals;

sensor_mode = "noisy";
% sensor_mode = "ideal";

% filt_under_test = "butter";
filt_under_test = "kalman";

% ctrl_under_test = "exhaust";
ctrl_under_test = "quantile_effort";

simin = Simulink.SimulationInput("sim_controller");

orkdata = doc.simulate(doc.sims("MATLAB"), outputs = "ALL", stop = "APOGEE");
inits = get_initial_data(orkdata);

switch sensor_mode
    case "noisy"
        simin = structs2inputs(simin, accel_params("lsm6dsl"));
        simin = structs2inputs(simin, baro_params("bmp388"));
    case "ideal"
        simin = structs2inputs(simin, accel_params("ideal"));
        simin = structs2inputs(simin, baro_params("ideal"));
    otherwise
        error ("Unrecognzied case %s", sensor_mode);
end

switch filt_under_test
    case "butter"
        simin = simin.setVariable(filter_mode = "butter");
        simin = structs2inputs(simin, alt_filter_params("designed"));
        simin = structs2inputs(simin, accel_filter_params("designed"));
    case "kalman"
        params = kalman_filter_params("accel-bias");
        % the initial state is not likely to be perfect, but this is more
        % realistic than using all-zeros 
        initdata = retime(orkdata, seconds(inits.t_0));
        params.kalm_initial = [initdata.Altitude; 
            initdata.("Vertical velocity");
            initdata.("Vertical acceleration");
            9.81];

        simin = simin.setVariable(filter_mode = "kalman");
        simin = structs2inputs(simin, params);

    otherwise
        error ("Unrecognzied case %s", filt_under_test);
end

lookups = matfile(pfullfile("data", "lutdata.mat"), Writable = false);
switch ctrl_under_test
    case "exhaust"
        simin = simin.setVariable(controller_rate = 10);
        simin = simin.setVariable(control_mode = "exhaust");
        simin = simin.setVariable(baro_lut = ...
            xarray2lut(lookups.exhaust_100_by_100, ["vel", "alt"]));
    case "quantile_effort"
        simin = simin.setVariable(controller_rate = 10);
        simin = simin.setVariable(control_mode = "quant");
        simin = simin.setVariable(lower_bound_lut = ...
            xarray2lut(lookups.lower_bounds, "alt"));
        simin = simin.setVariable(upper_bound_lut = ...
            xarray2lut(lookups.upper_bounds, "alt"));
    otherwise
        error ("Unrecognzied case %s", ctrl_under_test);
end

simin = structs2inputs(simin, vehicle_params("openrocket"));
simin = structs2inputs(simin, inits);
simin = simin.setVariable(dt = 0.001);

simout = sim(simin);
logs = extractTimetable(simout.logsout);
logs = fillmissing(logs, "previous");

% plot setup
true_args = {"DisplayName", "True"};
meas_args = {"DisplayName", "Measured"};
est_args = {"DisplayName", "Estimated"};

figure(name = "State estimation");
layout = tiledlayout(3,2);
layout.TileIndexing = "rowmajor";

nexttile; hold on; grid on;
plot(logs.Time, logs.position(:,2), true_args{:});
% plot(logs.Time, logs.altitude_meas, meas_args{:});
plot(logs.Time, logs.altitude_est, est_args{:});
ylabel("Altitude");
ysecondarylabel("m AGL");

nexttile; hold on; grid on;
plot(logs.Time, logs.altitude_est - logs.position(:,2));
ylabel("Error");
ysecondarylabel("m");

nexttile; hold on; grid on;
plot(logs.Time, logs.velocity(:,2), true_args{:});
% plot(logs.Time, logs.velocity_meas, meas_args{:});
plot(logs.Time, logs.velocity_est, est_args{:});
ylabel("Vertical velocity");
ysecondarylabel("m/s");

nexttile; hold on; grid on;
plot(logs.Time, logs.velocity_est - logs.velocity(:,2));
ylabel("Error");
ysecondarylabel("m/s");
legend;

nexttile; hold on; grid on;
plot(logs.Time, logs.acceleration(:,2), true_args{:});
plot(logs.Time, logs.accel_meas, meas_args{:});
plot(logs.Time, logs.accel_est, est_args{:});
ylabel("Vertical acceleration");
ysecondarylabel("m/s^2");
xlabel("Time");
legend;

nexttile; hold on; grid on;
plot(logs.Time, logs.accel_est - logs.acceleration(:,2));
ylabel("Error");
ysecondarylabel("m/s^2");
xlabel("Time");

figure(name = "Effort history");
layout = tiledlayout(3,1);

nexttile([2 1]); hold on; grid on;
plot(logs.position(:,2), logs.velocity(:,2), true_args{:});
plot(logs.altitude_est, logs.velocity_est, est_args{:});
xlabel("Altitude");
xsecondarylabel("m AGL");
ylabel("Vertical velocity");
ysecondarylabel("m/s");
legend;

nexttile; hold on; grid on;
plot(logs.Time, logs.effort, "--", SeriesIndex = 1, DisplayName = "Controller effort");
plot(logs.Time, logs.extension, "-", SeriesIndex = 1, DisplayName = "Extension");
legend;
ylabel("Airbrake extension");
xlabel("Time");

figure(name = "Covariance")
layout = tiledlayout(4, 1);
n_sigma = 3;

nexttile; hold on; grid on;
plot(logs.Time, logs.position(:,2) - logs.altitude_est);
plot(logs.Time, [-1, 1] .* n_sigma .* sqrt(logs.estimate_cov(:, 1, 1)), "--k");
ylabel("Altitude [m]")

nexttile; hold on; grid on;
plot(logs.Time, logs.velocity(:,2) - logs.velocity_est);
plot(logs.Time, [-1, 1] .* n_sigma .* sqrt(logs.estimate_cov(:, 2, 2)), "--k");
ylabel("Velocity [m/s]")

nexttile; hold on; grid on;
plot(logs.Time, logs.acceleration(:,2) - logs.accel_est);
plot(logs.Time, [-1, 1] .* n_sigma .* sqrt(logs.estimate_cov(:, 3, 3)), "--k");
ylabel("Acceleration [m/s^2]")

nexttile; hold on; grid on;
plot(logs.Time, (logs.body_accel - logs.acceleration(:,2)) - logs.state_est(:, 4));
plot(logs.Time, [-1, 1] .* n_sigma .* sqrt(logs.estimate_cov(:, 4, 4)), "--k");
ylabel("Bias [m/s^2]")

figure(name = "Innovation")
layout = tiledlayout(2, 1);

nexttile; hold on; grid on;
plot(logs.Time, logs.innovation(:, 1));
plot(logs.Time, [-1, 1] .* n_sigma .* sqrt(logs.innovation_cov(:, 1, 1)), "--k");
ylabel("Altitude [m]")

nexttile; hold on; grid on;
plot(logs.Time, logs.innovation(:, 2));
plot(logs.Time, [-1, 1] .* n_sigma .* sqrt(logs.innovation_cov(:, 2, 2)), "--k");
ylabel("Acceleration [m/s^2]")
