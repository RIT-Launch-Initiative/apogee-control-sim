clear;
project_globals;

sensor_mode = "noisy";
% sensor_mode = "ideal";

% filt_under_test = "butter";
filt_under_test = "kalman";

% ctrl_under_test = "exhaust";
ctrl_under_test = "quantile_effort";
% ctrl_under_test = "s_function";

simin = Simulink.SimulationInput("sim_controller");

orkdata = doc.simulate(doc.sims(sim_name), outputs = "ALL", stop = "APOGEE", atmos = airdata);
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
        params = kalman_filter_params("alt-accel-bias");
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

switch ctrl_under_test
    case "exhaust"
        simin = simin.setVariable(controller_rate = 10);
        simin = simin.setVariable(control_mode = "exhaust");
        simin = simin.setVariable(baro_lut = ...
            xarray2lut(lookups.exhaust_100_by_100, ["vel", "alt"]));
    case "quantile_effort"
        % loads the .mat file if is exists, otherwise it generates it
        if isfile(luts_file)
            % Preloads the lookup table if it is available
            lookups = matfile(luts_file, Writable = false);
        else
            generate_quant_luts; % Generates the quantile lookup table
            lookups = matfile(luts_file, Writable = false);
        end

        simin = simin.setVariable(controller_rate = 10);
        simin = simin.setVariable(control_mode = "quant");
        simin = simin.setVariable(lower_bound_lut = ...
            xarray2lut(lookups.lower_bounds, "alt"));
        simin = simin.setVariable(upper_bound_lut = ...
            xarray2lut(lookups.upper_bounds, "alt"));
    case "s_function"
        simin = simin.setVariable(controller_rate = 10);
        simin = simin.setVariable(control_mode = "s");
    otherwise
        error ("Unrecognzied case %s", ctrl_under_test);
end

simin = structs2inputs(simin, vehicle_params("openrocket", rocket_file, sim_name));
simin = structs2inputs(simin, inits);
simin = simin.setVariable(dt = 0.001);

simout = sim(simin);
logs = extractTimetable(simout.logsout);
logs = fillmissing(logs, "previous");

% plot setup
true_args = {"DisplayName", "True"};
meas_args = {"DisplayName", "Measured"};
est_args = {"DisplayName", "Estimated"};

this_fig = figure(name = "Effort history");

hold on; grid on;
% plot(logs.position(:,2), logs.velocity(:,2), true_args{:});
plot(logs.altitude_est, logs.velocity_est, est_args{:}, "LineWidth", 2);
xlabel("Altitude");
xsecondarylabel("m AGL");
ylabel("Vertical velocity");
ysecondarylabel("m/s");
ylim([0 250]);
xlim([logs.altitude_est(11), logs.altitude_est(end)])
% this_fig.WindowStyle = 'normal';
% this_fig.Units = "pixels";
% this_fig.Position = [0 0 400 300];

% Closes all simulink models after running
% Fixes some errors if you need to regenerate data
bdclose('all')
