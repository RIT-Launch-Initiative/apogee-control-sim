clear;
project_globals;

sensor_mode = "noisy";
% sensor_mode = "ideal";

% filt_under_test = "butter";
filt_under_test = "kalman";

ctrl_under_test = "exhaust";
% ctrl_under_test = "quantile_effort";
% ctrl_under_test = "quantile_tracking";


cases = runs.ork_100;
% cases = cases(1:10, :);

target_name = sprintf("filt-%s_ctrl-%s_%d", filt_under_test, ctrl_under_test, height(cases));

simin = Simulink.SimulationInput("sim_controller");
baseline_params = vehicle_params("openrocket");
simin = structs2inputs(simin, baseline_params);
simin = simin.setVariable(dt = 0.01);

simin = simin.setModelParameter(SimulationMode = "accelerator");

orkdata = doc.simulate(doc.sims("MATLAB"), outputs = "ALL", stop = "APOGEE");
inits = get_initial_data(orkdata);
simin = simin.setVariable(t_0 = inits.t_0);

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

switch ctrl_under_test
    case "exhaust"
        simin = simin.setVariable(controller_rate = 10);
        simin = simin.setVariable(control_mode = "exhaust");
        simin = simin.setVariable(baro_lut = ...
            xarray2lut(luts.exhaust_100_by_100, ["vel", "alt"]));
    case "quantile_effort"
        simin = simin.setVariable(controller_rate = 10);
        simin = simin.setVariable(control_mode = "quant");
        simin = simin.setVariable(lower_bound_lut = ...
            xarray2lut(luts.lower_bounds, "alt"));
        simin = simin.setVariable(upper_bound_lut = ...
            xarray2lut(luts.upper_bounds, "alt"));
    case "quantile_tracking"
        % simin = simin.setVariable(controller_rate = 100);
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
        params = kalman_filter_params("alt-accel-bias");

        % This is not strictly accurate;
        % - each simulation will have a different initial state
        % - the estimated iniital state will not be the true state
        % however, the filter will quickly settle to a close-to-true value and
        % this is better than initializing with all zeros
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

fprintf("Creating Monte Carlo input array...");

start = tic;
monte_inits = table2struct(cases(:, ["position_init", "velocity_init"]));
for i_case = 1:length(monte_inits)
    % these are rows of a table, but need to be column vectors in the simulation
    monte_inits(i_case).position_init = monte_inits(i_case).position_init'; 
    monte_inits(i_case).velocity_init = monte_inits(i_case).velocity_init'; 
    monte_inits(i_case).DRAG_LUT = xarray2lut(...
        cases.cd_scale(i_case) * baseline_params.cd_array, ...
        ["mach", "effort"], "drag_table");
end
simins = structs2inputs(simin, monte_inits);

fprintf(" finished in %.1f sec\n", toc(start));
simouts = sim(simins, ShowProgress = "on", StopOnError = true, UseFastRestart = "on");
% parsim() gets stuck on configuring the cache folder for some reason


lower_bounds = luts.lower_bounds;
upper_bounds = luts.upper_bounds;

traj_figure = figure(name = "Monte Carlo raw outputs");
layout = tiledlayout(3,1);

traj_ax = nexttile([2 1]); hold on; grid on;
xlim([min(lower_bounds.alt), max(lower_bounds.alt)]);
ylim([min(double(lower_bounds)), max(double(upper_bounds))]);
xlabel("Altitude");
xsecondarylabel("m AGL");
ylabel("Vertical velocity");
ysecondarylabel("m/s");

effort_ax = nexttile; hold on; grid on;

ylabel("Extension");
xlabel("Time");

colors = colororder; % get default MATLAB color sequence 
col = [colors(1,:) 0.1];

cases.ctrl_apogee = NaN(height(cases), 1);
for i_sim = 1:length(simouts)
    logs = extractTimetable(simouts(i_sim).logsout);
    logs = fillmissing(logs, "previous");

    % decimate the plot so it isn't as astonishingly laggy in a PDF
    logs = retime(logs, "regular", "linear", SampleRate = 5); 

    cases.ctrl_apogee(i_sim) = simouts(i_sim).apogee;
    plot(traj_ax, logs.altitude_est, logs.velocity_est, Color = col);
    plot(effort_ax, logs.Time, logs.extension, Color = col);
end

axes(traj_ax);
plot(lower_bounds, "--k");
plot(upper_bounds, "--k");

fprintf("Target: %s\n", target_name);
fprintf("Final apogee error quartiles: [%+.1f %+.2f %+.1f] m\n", ...
    prctile(cases.ctrl_apogee, [25 50 75]) - apogee_target);

print2size(traj_figure, fullfile(graphics_path, target_name + ".pdf"), [350 400]);


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

