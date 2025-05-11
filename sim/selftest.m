clear;
rkt_file = pfullfile("data", "CRUD.ork");
sim_file = pfullfile("sim", "sim_2dof");
doc = openrocket(rkt_file);

%% Configure simulation
vehicle_data = get_vehicle_data(doc);
data = doc.simulate(doc.sims(1), outputs = "ALL", stop = "APOGEE");
inits = get_initial_data(data);

inits.dt = 0.01;
inits.control_brake = false;
inits.const_brake = 0;

%% Simulate
simin = struct2input(sim_file, vehicle_data);
simin = struct2input(simin, inits);

simout = sim(simin);
outputs = extractTimetable(simout.yout);
logs = extractTimetable(simout.logsout);

%% Plot and compare
figure;
layout = tiledlayout("vertical");
layout.TileSpacing = "tight";

nexttile; hold on; grid on;
plot(data.Time, data.Altitude, DisplayName = "OpenRocket");
plot(outputs.Time, outputs.Altitude, DisplayName = "Simulink true");
plot(logs.Time, logs.altitude_measured, DisplayName = "Simulink measured");
ylabel("Altitude"); ysecondarylabel("m AGL");
legend(Location = "northoutside", Orientation = "horizontal");

nexttile; hold on; grid on;
plot(data.Time, data.("Drag force"), DisplayName = "OpenRocket");
plot(logs.Time, logs.drag_force, DisplayName = "Simulink true");
plot(logs.Time, -vehicle_data.MASS_DRY * logs.accel_measured(:, 1), DisplayName = "Simulink measured");
ylabel("Drag force"); ysecondarylabel("N");

xlabel(layout, "Time");
