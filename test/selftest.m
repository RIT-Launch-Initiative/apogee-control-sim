clear;
project_globals;

%% Configure simulation
vehicle_data = get_vehicle_data(doc);
orsim = doc.sims(1);
opts = orsim.getOptions();
opts.setISAAtmosphere(true);
data = doc.simulate(orsim, outputs = "ALL", stop = "APOGEE");
inits = get_initial_data(data);

inits.dt = 0.01;
inits.control_mode = "const";
inits.const_brake = 0;

%% Simulate
simin = structs2inputs(sim_file, vehicle_data);
simin = structs2inputs(simin, inits);

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
plot(logs.Time, -vehicle_data.MASS_DRY * logs.accel_measured(:, 1), DisplayName = "Simulink measured");
ylabel("Drag force"); ysecondarylabel("N");

xlabel(layout, "Time");
