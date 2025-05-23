clear;
generate_table = true;

%% DEFINE INPUT FILES
project_globals;

%% LUT RANGES

maker_file = pfullfile("sim", "sim_const");
vehicle_data = vehicle_params(doc);
brake_data = get_brake_data("ideal");
simin = structs2inputs(maker_file, vehicle_data);
simin = structs2inputs(simin, brake_data);

alts = [5 10 20 50];
vels = [5 10 21];
num_alts = 20;
num_vels = 10;
altitudes = linspace(1200, apogee_target - 10, num_alts); % [m]
quantile_ctrl = make_quantile_lut(simin, apogee_target, altitudes, num_vels);

%% Test table
sim_file = pfullfile("sim", "sim_controller");
data = doc.simulate(doc.sims(1), outputs = "ALL", stop = "APOGEE");
inits = get_initial_data(data);
inits.dt = 0.01;

ctrl.control_mode = "quant";
ctrl.observer_rate = 100;
ctrl.controller_rate = 10;
ctrl.upper_bound_lut = xarray2lut(quantile_ctrl.upper_bound_lut);
ctrl.lower_bound_lut = xarray2lut(quantile_ctrl.lower_bound_lut);
ctrl.quantile_lut = xarray2lut(quantile_ctrl.quantile_lut);

simin = structs2inputs(sim_file, vehicle_data);
simin = structs2inputs(simin, get_brake_data("noisy"));
simin = structs2inputs(simin, inits);
simin = structs2inputs(simin, ctrl);

simout = sim(simin);
logs = extractTimetable(simout.logsout);
logs = fillmissing(logs, "previous");

fprintf("Achieved apogee: %.1f\n", simout.apogee);

%
% simout_figure = figure(name = "Motion");
% layout = tiledlayout("vertical");
% layout.TileSpacing = "tight";
%
% nexttile; hold on; grid on;
% plot(data.Time, data.Altitude, DisplayName = "Baseline");
% plot(logs.Time, logs.position(:,2), DisplayName = "Simulated");
% % plot(logs.Time, logs.altitude_measured, DisplayName = "Measured");
% % plot(logs.Time, logs.altitude_est, DisplayName = "Estimated")
% legend;
% ylabel("Altitude");
%
% nexttile; hold on; grid on;
% plot(data.Time, data.("Vertical velocity"), DisplayName = "Baseline");
% plot(logs.Time, logs.velocity(:, 2), DisplayName = "Simulated");
% % plot(logs.Time, logs.vvel_est, DisplayName = "Estimated");
% legend;
% ylabel("Vertical Velocity");
%
% nexttile; hold on; grid on;
% plot(logs.Time, logs.extension);
% ylabel("Control effort")
%
% nexttile; hold on; grid on;
% plot(data.Time, data.("Drag force"), DisplayName = "Baseline");
% plot(logs.Time, logs.drag_force, DisplayName = "Simulated");
% ylabel("Drag force");
%
% phase_traj_figure = figure(name = "Basic phase trajectory");
% hold on; grid on;
% plot(data.Altitude, data.("Vertical velocity"), DisplayName = "Baseline");
% plot(logs.position(:,2), logs.velocity(:, 2), DisplayName = "Controlled");
% plot(altitudes, uppers, "--k", HandleVisibility = "off");
% plot(altitudes, lowers, "--k", Handlevisibility = "off");
% xlim([-Inf apogee_target]);
% xlabel("Altitude");
% xsecondarylabel("m AGL");
% ylabel("Vertical velocity");
% ysecondarylabel("m/s");
% legend;
%
% export_at_size(phase_traj_figure, "basic_phase_trajs.pdf", [500 400]);
%
