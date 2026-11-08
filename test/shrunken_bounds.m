clear;
project_globals;

lower_bounds = luts.lower_bounds;
upper_bounds = luts.upper_bounds;

const_sim_path = pfullfile("sim", "sim_const");
% altitudes = linspace(alt_start, apogee_target, 100);
altitudes = 1002;
% velocities = 250;
% velocities = 243;
desired_effort = 0.8;
velocities = interp1(lower_bounds.alt, (upper_bounds.data - lower_bounds.data) * desired_effort, altitudes) + interp1(lower_bounds.alt, lower_bounds.data, altitudes);

init_params.t_0 = 0;
init_params.position_init = [0 altitudes];
init_params.velocity_init = [0 velocities];

const_simin = structs2inputs(const_sim_path, vehicle_params("openrocket", rocket_file, sim_name));
const_simin = structs2inputs(const_simin, init_params);
const_simin = structs2inputs(const_simin, struct(brake_on = 0, brake_off = 100));

% Zero effort sim
zero_simin = structs2inputs(const_simin, struct(const_brake = 0, brake_on = 0, brake_off = 100));
zero_simout = sim(zero_simin);
zero_logs = zero_simout.logsout.extractTimetable;

% Full effort sim
full_simin = structs2inputs(const_simin, struct(const_brake = 1, brake_on = 0, brake_off = 100));
full_simout = sim(full_simin);
full_logs = full_simout.logsout.extractTimetable;



figure(Name="Thi state's trajectory");
tiledlayout(2,1, TileSpacing="compact", Padding="compact");

nexttile; hold on; grid on;
plot(zero_logs.Time, zero_logs.position(:,2));
plot(full_logs.Time, full_logs.position(:,2));

nexttile; hold on; grid on;
plot(zero_logs.Time, zero_logs.velocity(:,2));
plot(full_logs.Time, full_logs.velocity(:,2));



figure(Name="Bounds of this specifi state");
tiledlayout(1,1, TileSpacing="compact", Padding="compact");

nexttile; hold on; grid on;
plot(lower_bounds.alt, lower_bounds.data, "--k", LineWidth=1);
plot(upper_bounds.alt, upper_bounds.data, "--k", LineWidth=1);
plot(upper_bounds.alt, (lower_bounds.data + upper_bounds.data)/2, "--r", LineWidth=1);
plot(zero_logs.position(:,2), zero_logs.velocity(:,2), LineWidth=1.5);
plot(full_logs.position(:,2), full_logs.velocity(:,2), LineWidth=1.5);

xlim([min(lower_bounds.alt) 3600]);
ylim([0 max(upper_bounds.data)]);