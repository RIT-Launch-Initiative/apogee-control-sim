%% MODEL SELF TEST
% verify the controller and cutimized model produce results consistent with
% OpenRocket when run with a constant zero extension

clear;
project_globals;

%% Set up orkdata

orksim = doc.sims("MATLAB");
opts = orksim.getOptions();
opts.setISAAtmosphere(true);
opts.setWindSpeedAverage(0);
opts.setWindSpeedDeviation(0);
% opts.setLaunchRodAngle(deg2rad(70));
orkdata = doc.simulate(orksim, outputs = "ALL", stop = "APOGEE");

vehicle_data = vehicle_params("openrocket");
inits = get_initial_data(orkdata);
inits.dt = 1/100;

% set up constant extension of 0
ctrl.control_mode = "const"; % for sim_controller
ctrl.filter_mode = "through";
ctrl.const_brake = 0;
ctrl.brake_on = 0;
ctrl.brake_off = 100; % arbitrary large value
ctrl.observer_rate = 100;
ctrl.controller_rate = 10;

%% Simulate
simin_full = structs2inputs("sim_controller", vehicle_data, ...
    accel_params("ideal"), baro_params("ideal"), actuator_params("ideal"), ...
    inits, ctrl);

simin_cut = structs2inputs("sim_const", vehicle_data, inits, ctrl);
simin_cut = simin_cut.setModelParameter(FastRestart = "on", SimulationMode = "accelerator");

%% Get simulated data
simout_full = sim(simin_full);
logs_full = extractTimetable(simout_full.logsout);
logs_full = fillmissing(logs_full, "previous"); % multi-rate simulation fills logs with a bunch of NaNs
simout_cut = sim(simin_cut);
logs_cut = extractTimetable(simout_cut.logsout);

compare_full = synchronize(logs_full, orkdata(1:end-2, :), "first", "linear");
compare_cut = synchronize(logs_cut, orkdata(1:end-2, :), "first", "linear");

% Time test
num_runs = 10;
timing_inputs = repmat(simin_cut, 1, num_runs);

t_start = tic;
simouts = sim(timing_inputs);
total_time = toc(t_start);
set_param(simin_cut.ModelName, FastRestart = "off"); % exit Fast Restart mode automatically

fprintf("%d simulations at %.2f sec/sim\n", num_runs, total_time/num_runs);

%% Plot and compare

figure(name = "Drag curves");
hold on; grid on;
plot(compare_full.("Mach number"), compare_full.("Drag coefficient"), ...
    DisplayName = "Simulated");
plot(vehicle_data.cd_array.pick(effort = 0), ...
    DisplayName = "Calculator invoked");
legend;
ylim([0 0.5]);
xlabel("Mach number");
ylabel("Drag coefficient");

figure(name = "Output comparison");
layout = tiledlayout(3,2);
layout.TileSpacing = "tight";
layout.TileIndexing = "rowmajor";

nexttile; hold on; grid on;
plot(logs_full.Time, logs_full.altitude_meas, DisplayName = "Full sim measured");
plot(orkdata.Time, orkdata.Altitude, DisplayName = "OpenRocket");
plot(logs_full.Time, logs_full.position(:, 2), DisplayName = "Full sim true");
plot(logs_cut.Time, logs_cut.position(:, 2), DisplayName = "Cut sim true");
ylabel("Altitude"); ysecondarylabel("m AGL");
legend;

nexttile; hold on; grid on;
plot(compare_full.Time, compare_full.position(:,2) - compare_full.Altitude, ...
    DisplayName = "Full");
plot(compare_cut.Time, compare_cut.position(:,2) - compare_cut.Altitude, ...
    DisplayName = "Cut");
ylabel("Error"); ysecondarylabel("m");
legend;

%% Sensor measurement comparison
nexttile; hold on; grid on;
plot(orkdata.Time, orkdata.("Drag force") .* cos(orkdata.("Angle of attack")), DisplayName = "OpenRocket");
plot(logs_full.Time, -vehicle_data.MASS_DRY * logs_full.accel_meas, DisplayName = "Simulink measured");
ylabel("Drag force"); ysecondarylabel("N");

nexttile; hold on; grid on;
plot(compare_full.Time, -vehicle_data.MASS_DRY * compare_full.accel_meas - ...
    compare_full.("Drag force") .* cos(compare_full.("Angle of attack")))
ylabel("Error"); ysecondarylabel("N");

nexttile; hold on; grid on;
plot(compare_full.Time, compare_full.("Vertical acceleration"));
plot(compare_full.Time, compare_full.accel_meas - vehicle_data.GRAVITY);
ylabel("Vertical acceleration"); ysecondarylabel("m/s^2");

nexttile; hold on; grid on;
plot(compare_full.Time, compare_full.accel_meas - vehicle_data.GRAVITY - ...
    compare_full.("Vertical acceleration"));
ylabel("Error"); ysecondarylabel("m/s^2");

xlabel(layout, "Time");
