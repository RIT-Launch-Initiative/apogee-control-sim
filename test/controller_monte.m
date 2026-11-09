clear;
project_globals;

turn_airbrakes_off = true;

sensor_mode = "noisy";
% sensor_mode = "ideal";

% filt_under_test = "butter";
filt_under_test = "kalman";

% ctrl_under_test = "exhaust";
ctrl_under_test = "quantile_effort";
% ctrl_under_test = "s_function";
% ctrl_under_test = "quantile_tracking";

% loads the .mat file if is exists, otherwise it generates it
if isfile(runs_file)
    % Preloads the variations for the monte carlo if it is available
    lookups = matfile(runs_file, Writable = false);
else
    generate_monte_cases; % Generates the variations for the monte carlo
    lookups = matfile(runs_file, Writable = false);
end

cases = runs.ork_400;
% cases = cases(1:10, :);

target_name = sprintf("filt-%s_ctrl-%s_%d", filt_under_test, ctrl_under_test, height(cases));

simin = Simulink.SimulationInput("sim_controller");
baseline_params = vehicle_params("openrocket", rocket_file, sim_name);
simin = structs2inputs(simin, baseline_params);
simin = simin.setVariable(dt = 0.01);

simin = simin.setModelParameter(SimulationMode = "accelerator");

orkdata = doc.simulate(doc.sims(sim_name), outputs = "ALL", stop = "BURNOUT");
inits = get_initial_data(orkdata);
simin = simin.setVariable(t_0 = inits.t_0);

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

switch ctrl_under_test
    case "exhaust"
        simin = simin.setVariable(controller_rate = 100);
        simin = simin.setVariable(control_mode = "exhaust");
        simin = simin.setVariable(baro_lut = ...
            xarray2lut(luts.exhaust_100_by_100, ["vel", "alt"]));
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
            xarray2lut(luts.lower_bounds, "alt"));
        simin = simin.setVariable(upper_bound_lut = ...
            xarray2lut(luts.upper_bounds, "alt"));
    case "s_function"
        simin = simin.setVariable(controller_rate = 100);
        simin = simin.setVariable(control_mode = "s");
    case "quantile_tracking"
        % simin = simin.setVariable(controller_rate = 1000);
        % simin = simin.setVariable(control_mode = "tracking");
        % simin = simin.setVariable(lower_bound_lut = ...
        %     xarray2lut(luts.lower_bounds, "alt"));
        % simin = simin.setVariable(upper_bound_lut = ...
        %     xarray2lut(luts.upper_bounds, "alt"));
    otherwise
        error ("Unrecognzied case %s", ctrl_under_test);
end

switch filt_under_test
    case "butter"
        simin = simin.setVariable(filter_mode = "butter");
        simin = structs2inputs(simin, alt_filter_params("designed"));
        simin = structs2inputs(simin, accel_filter_params("designed"));
    case "kalman"
        params = kalman_filter_params("RISK-flown");
        params.kalm_initial = [0;
                               0;
                               0;
                               9.8];

        simin = simin.setVariable(filter_mode = "kalman");
        simin = structs2inputs(simin, params);

    otherwise
        error ("Unrecognzied case %s", filt_under_test);
end

simin = simin.setVariable(turn_airbrakes_off = turn_airbrakes_off);
simin = simin.setVariable(time_start = time_start);

fprintf("Creating Monte Carlo input array...");

simins = structs2inputs(simin, table2struct(cases(:, "orkdata_for_simulink")));

start = tic;
fprintf(" finished in %.1f sec\n", toc(start));

% simouts = sim(simins, ShowProgress = "on", StopOnError = true, UseFastRestart = "on");
simouts = parsim(simins, ShowProgress="on", StopOnError="on", UseFastRestart="on");

%% Plot
lower_bounds = luts.lower_bounds;
upper_bounds = luts.upper_bounds;

traj_figure = figure(name = "Monte Carlo raw outputs");
layout = tiledlayout(3,1);

traj_ax = nexttile([2 1]); hold on; grid on;
% xlim([min(lower_bounds.alt), max(lower_bounds.alt)*1.01]);
ylim([min(double(lower_bounds)), max(double(upper_bounds))]);
xlabel("Altitude");
xsecondarylabel("m AGL");
ylabel("Vertical velocity");
ysecondarylabel("m/s");

effort_ax = nexttile; hold on; grid on;

ylabel("Extension");
xlabel("Time");

colors = colororder; % get default MATLAB color sequence 
col = [colors(1,:) interp1([1 10 40 100 500 1e4], [1 0.4 0.2 0.1 0.02 0], height(cases), "linear", "extrap")];

cases.ctrl_apogee = NaN(height(cases), 1);
for i_sim = 1:length(simouts)
    logs = extractTimetable(simouts(i_sim).logsout);
    logs = fillmissing(logs, "previous");

    % decimate the plot so it isn't as astonishingly laggy in a PDF
    % logs = retime(logs, "regular", "linear", SampleRate = 5); 

    cases.ctrl_apogee(i_sim) = simouts(i_sim).apogee;
    plot(traj_ax, logs.altitude_est, logs.velocity_est, Color = col);
    plot(effort_ax, logs.Time, logs.extension, Color = col);
end

axes(traj_ax);
plot(lower_bounds, "--k");
plot(upper_bounds, "--k");

histogram(traj_ax, cases.ctrl_apogee(:),25);
xlim([min(lower_bounds.alt), max([lower_bounds.alt;cases.ctrl_apogee(:)])*1.01]);

fprintf("Target: %s\n", target_name);
fprintf("Final apogee error quartiles: [%+.1f %+.2f %+.1f] m\n", ...
    prctile(cases.ctrl_apogee, [25 50 75]) - apogee_target);

% print2size(traj_figure, fullfile(graphics_path, target_name + ".pdf"), [350 400]);


% independent_vars = ["cd_scale", "wind_speed", "wind_off", "temp", "rod_angle"];
% labels = ["C_D scale", "Wind speed", "Wind offset", "Temperature", "Rod angle"];
% units = ["", "m/s", "deg", char(176) + "C", "deg"];
% funcs = {@(v) v, @(v) v, @rad2deg, @(v) v - 273.15, @rad2deg};
%
% baseline_fig = figure(name = "Baseline sensitivities");
% layout = tiledlayout("flow");
% for i_var = 1:length(independent_vars)
%     nexttile; hold on; grid on;
%
%     transform = funcs{i_var};
%     xdata = transform(cases.(independent_vars(i_var)));
%     scatter(xdata, cases.apogee, 20, "k", "x");
%     yline(apogee_target, "--k");
%
%     xlabel(labels(i_var));
%     xsecondarylabel(units(i_var));
%     ylabel("Baseline apogee");
%     ysecondarylabel("m AGL")
% end
% linkaxes(layout.Children, "y");
%
%
% ctrl_fig = figure(name = "Controller sensitivities");
% layout = tiledlayout("flow");
% for i_var = 1:length(independent_vars)
%     nexttile; hold on; grid on;
%
%     transform = funcs{i_var};
%     xdata = transform(cases.(independent_vars(i_var)));
%     yline(apogee_target, "--k");
%     scatter(xdata, cases.ctrl_apogee, 20, "k", "+");
%
%     xlabel(labels(i_var));
%     xsecondarylabel(units(i_var));
%     ylabel("Controlled apogee");
%     ysecondarylabel("m AGL");
% end
% linkaxes(layout.Children, "y");

% Closes all simulink models after running
% Fixes some errors if you need to regenerate data
% bdclose('all')