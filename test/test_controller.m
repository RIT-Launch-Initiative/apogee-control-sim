clear; 

project_globals;

vehicle_data = get_vehicle_data(doc);
data = doc.simulate(doc.sims(1), outputs = "ALL", stop = "APOGEE");
inits = get_initial_data(data);
inits.dt = 0.01;

ctrl.control_mode = "baro";
ctrl.controller_rate = 1/inits.dt;
% [ctrl.pos_num, ctrl.pos_den] = butter(4, 20/(ctrl.controller_rate/2), "low");
% [ctrl.vel_num, ctrl.vel_den] = butter(4, 20/(ctrl.controller_rate/2), "low");
ctrl.pos_num = 1; ctrl.pos_den = 1;
ctrl.vel_num = 1; ctrl.vel_den = 1;
ctrl.baro_lut = xarray2lut(luts.lut_100);

simin = structs2inputs(simin, vehicle_data);
simin = structs2inputs(simin, inits);
simin = structs2inputs(simin, ctrl);

simout = sim(simin);
logs = extractTimetable(simout.logsout)

fprintf("Achieved apogee: %.1f\n", simout.apogee);

figure(name = "Motion");
layout = tiledlayout("vertical");
layout.TileSpacing = "tight";

nexttile; hold on; grid on;
plot(data.Time, data.Altitude, DisplayName = "Baseline");
plot(logs.Time, logs.position(:,2), DisplayName = "Simulated");
plot(logs.Time, logs.altitude_measured, DisplayName = "Measured");
plot(logs.Time, logs.altitude_est, DisplayName = "Estimated")
legend;
ylabel("Altitude");

nexttile; hold on; grid on;
plot(data.Time, data.("Vertical velocity"), DisplayName = "Baseline");
plot(logs.Time, logs.velocity(:, 2), DisplayName = "Simulated");
plot(logs.Time, logs.vvel_est, DisplayName = "Estimated");
legend;
ylabel("Vertical Velocity");

nexttile; hold on; grid on;
plot(logs.Time, logs.extension);
ylabel("Control effort")

nexttile; hold on; grid on;
plot(data.Time, data.("Drag force"), DisplayName = "Baseline");
plot(logs.Time, logs.drag_force, DisplayName = "Simulated");
ylabel("Drag force");
