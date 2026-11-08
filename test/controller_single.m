clear;
project_globals;

turn_airbrakes_off = false;
target_const_effort = 0.5;
Kp = 10; % Kp = 0 is constant effort
         % Kp > 0 is maximum margin
         % Kp = 10 is good value for settling time

% sensor_mode = "noisy";
sensor_mode = "ideal";

filt_under_test = "through";
% filt_under_test = "butter";
% filt_under_test = "kalman";

% ctrl_under_test = "exhaust";
% ctrl_under_test = "quantile_effort";
% ctrl_under_test = "s_function";
ctrl_under_test = "maxm";

simin = Simulink.SimulationInput("sim_controller");

orkdata = doc.simulate(doc.sims(sim_name), outputs = "ALL", stop = "APOGEE");
inits = get_initial_data(orkdata);

switch sensor_mode
    case "noisy"
        simin = structs2inputs(simin, accel_params("lsm6dsv-45-deg"));
        simin = structs2inputs(simin, baro_params("ms5611"));
    case "ideal"
        simin = structs2inputs(simin, accel_params("ideal"));
        simin = structs2inputs(simin, baro_params("ideal"));
    otherwise
        error ("Unrecognzied case %s", sensor_mode);
end

switch filt_under_test
    case "through"
        simin = simin.setVariable(filter_mode = "through");
    case "butter"
        simin = simin.setVariable(filter_mode = "butter");
        simin = structs2inputs(simin, alt_filter_params("designed"));
        simin = structs2inputs(simin, accel_filter_params("designed"));
    case "kalman"
        params = kalman_filter_params("RISK-flown");
        % the initial state is not likely to be perfect, but this is more
        % realistic than using all-zeros 
        initdata = retime(orkdata, seconds(inits.t_0));
        params.kalm_initial = [0; 
                               0;
                               0;
                               9.8];

        simin = simin.setVariable(filter_mode = "kalman");
        simin = structs2inputs(simin, params);
    otherwise
        error ("Unrecognzied case %s", filt_under_test);
end

switch ctrl_under_test
    case "exhaust"
        simin = simin.setVariable(controller_rate = 100);
        simin = simin.setVariable(control_mode = "exhaust");
        simin = simin.setVariable(baro_lut = ...
            xarray2lut(lookups.exhaust_100_by_100, ["vel", "alt"]));
    case "quantile_effort"
        % loads the .mat file if is exists, otherwise it generates it
        if isfile(luts_file)
            % Preloads the lookup table if it is available
            lookups = matfile(luts_file, Writable = false);
        else
            generate_bounds; % Generates the quantile lookup table
            lookups = matfile(luts_file, Writable = false);
        end

        simin = simin.setVariable(controller_rate = 100);
        simin = simin.setVariable(control_mode = "quant");
        simin = simin.setVariable(lower_bound_lut = ...
            xarray2lut(lookups.lower_bounds, "alt"));
        simin = simin.setVariable(upper_bound_lut = ...
            xarray2lut(lookups.upper_bounds, "alt"));
    case "s_function"
        simin = simin.setVariable(controller_rate = 100);
        simin = simin.setVariable(control_mode = "s");
    case "maxm"
        % loads the .mat file if is exists, otherwise it generates it
        if isfile(luts_file)
            % Preloads the lookup table if it is available
            lookups = matfile(luts_file, Writable = false);
        else
            generate_bounds; % Generates the quantile lookup table
            lookups = matfile(luts_file, Writable = false);
        end

        simin = simin.setVariable(controller_rate = 100);
        simin = simin.setVariable(control_mode = "maxm");
        simin = simin.setVariable(lower_bound_lut = ...
            xarray2lut(lookups.lower_bounds, "alt"));
        simin = simin.setVariable(upper_bound_lut = ...
            xarray2lut(lookups.upper_bounds, "alt"));

        simin = simin.setVariable(target_const_effort = target_const_effort);
        simin = simin.setVariable(Kp = Kp);
    otherwise
        error ("Unrecognzied case %s", ctrl_under_test);
end

simin = structs2inputs(simin, vehicle_params("openrocket", rocket_file, sim_name));
simin = structs2inputs(simin, inits);
simin = simin.setVariable(dt = 0.01);

% For starting simulation on ground
orkdata_for_simulink = orkdata(:,[]);
orkdata_for_simulink.position = [orkdata.("Lateral distance") orkdata.Altitude];
orkdata_for_simulink.velocity = [orkdata.("Lateral velocity") orkdata.("Vertical velocity")];
orkdata_for_simulink.acceleration = [orkdata.("Lateral acceleration") orkdata.("Vertical acceleration")];
orkdata_for_simulink.pitch = orkdata.("Vertical orientation (zenith)");
orkdata_for_simulink(seconds(0), :) = orkdata_for_simulink(1,:); % zero out OR weirdness at time zero
orkdata_for_simulink = sortrows(orkdata_for_simulink);
orkdata_for_simulink(1:2, :).position = [0 0; 0 0];
orkdata_for_simulink(1:2, :).velocity = [0 0; 0 0];
orkdata_for_simulink(1:2, :).acceleration = [0 0; 0 0];
simin = simin.setVariable(orkdata_for_simulink = orkdata_for_simulink);

simout = sim(simin);
logs = extractTimetable(simout.logsout);
logs = fillmissing(logs, "previous");

% plot setup
true_args = {"DisplayName", "True"};
meas_args = {"DisplayName", "Measured"};
est_args = {"DisplayName", "Estimated"};

figure(name = "State estimation");
layout = tiledlayout(3, 2, TileSpacing="compact", Padding="compact");
layout.TileIndexing = "rowmajor";

axes_states(1) = nexttile; hold on; grid on;
plot(logs.Time, logs.position(:,2), true_args{:});
% plot(logs.Time, logs.altitude_meas, meas_args{:});
plot(logs.Time, logs.altitude_est, est_args{:});
ylabel("Altitude");
ysecondarylabel("m AGL");

axes_states(end + 1) = nexttile; hold on; grid on;
plot(logs.Time, logs.altitude_est - logs.position(:,2));
ylabel("Error");
ysecondarylabel("m");

axes_states(end + 1) = nexttile; hold on; grid on;
plot(logs.Time, logs.velocity(:,2), true_args{:});
% plot(logs.Time, logs.velocity_meas, meas_args{:});
plot(logs.Time, logs.velocity_est, est_args{:});
ylabel("Vertical velocity");
ysecondarylabel("m/s");

axes_states(end + 1) = nexttile; hold on; grid on;
plot(logs.Time, logs.velocity_est - logs.velocity(:,2));
ylabel("Error");
ysecondarylabel("m/s");

axes_states(end + 1) = nexttile; hold on; grid on;
plot(logs.Time, logs.acceleration(:,2), true_args{:});
plot(logs.Time, logs.accel_meas, meas_args{:});
plot(logs.Time, logs.accel_est, est_args{:});
ylabel("Vertical acceleration");
ysecondarylabel("m/s^2");
xlabel("Time");
legend;

axes_states(end + 1) = nexttile; hold on; grid on;
plot(logs.Time, logs.accel_est - logs.acceleration(:,2));
ylabel("Error");
ysecondarylabel("m/s^2");
xlabel("Time");

linkaxes(axes_states, "x");


lower_bounds = luts.lower_bounds;
upper_bounds = luts.upper_bounds;

figure(name = "Effort history");
layout = tiledlayout(3,1);

nexttile([2 1]); hold on; grid on;

plot(logs.position(:,2), interp1(lower_bounds.alt, lower_bounds.data, logs.position(:,2)), "--k", DisplayName="Lower bound");
plot(logs.position(:,2), interp1(upper_bounds.alt, upper_bounds.data, logs.position(:,2)), "--k", DisplayName="Upper bound");

plot(logs.position(:,2), logs.velocity(:,2), true_args{:});
plot(logs.altitude_est, logs.velocity_est, est_args{:});
xline(apogee_target, DisplayName="Target apogee");
xlabel("Altitude");
xsecondarylabel("m AGL");
ylabel("Vertical velocity");
ysecondarylabel("m/s");
legend;
xlim([min(lower_bounds.alt) max(logs.position(:,2))*1.01]);
ylim([0 max(upper_bounds.data)])

nexttile; hold on; grid on;
plot(logs.Time, logs.effort, "--", SeriesIndex = 1, DisplayName = "Controller effort");
plot(logs.Time, logs.extension, "-", SeriesIndex = 1, DisplayName = "Extension");
yline(target_const_effort, "--k", DisplayName = "Target const. effort", LineWidth=2);
plot(logs.Time, logs.const_effort, "-r", SeriesIndex = 1, DisplayName = "Const. effort");
legend;
ylabel("Airbrake extension");
xlabel("Time");

% Closes all simulink models after running
% Fixes some errors if you need to regenerate data
% bdclose('all')
