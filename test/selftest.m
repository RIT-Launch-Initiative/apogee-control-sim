clear;
project_globals;

%% Configure simulation
sim_file = pfullfile("sim", "sim_controller");
vehicle_data = get_vehicle_data(doc);
orsim = doc.sims(1);
opts = orsim.getOptions();
opts.setISAAtmosphere(true);
data = doc.simulate(orsim, outputs = "ALL", stop = "APOGEE");
inits = get_initial_data(data);
inits.dt = 1/100;

ctrl.control_mode = "const";
ctrl.const_brake = 0;
ctrl.observer_rate = 100;
ctrl.controller_rate = 100;

%% Simulate
simin = structs2inputs("sim_controller", vehicle_data);
simin = structs2inputs(simin, inits);
simin = structs2inputs(simin, ctrl);

simout = sim(simin);
logs = extractTimetable(simout.logsout);

%% Plot and compare
figure(name = "Output comparison");
layout = tiledlayout("vertical");
layout.TileSpacing = "tight";

nexttile; hold on; grid on;
plot(data.Time, data.Altitude, DisplayName = "OpenRocket");
plot(logs.Time, logs.position(:, 2), DisplayName = "Simulink true");
plot(logs.Time, logs.altitude_measured, DisplayName = "Simulink measured");
ylabel("Altitude"); ysecondarylabel("m AGL");
legend(Location = "northoutside", Orientation = "horizontal");

nexttile; hold on; grid on;
plot(data.Time, data.("Drag force"), DisplayName = "OpenRocket");
plot(logs.Time, logs.drag_force, DisplayName = "Simulink true");
plot(logs.Time, -vehicle_data.MASS_DRY * logs.accel_measured, DisplayName = "Simulink measured");
ylabel("Drag force"); ysecondarylabel("N");

xlabel(layout, "Time");
