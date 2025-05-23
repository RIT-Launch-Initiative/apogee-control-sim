%% Reachable state phase-plane plots

clear;
project_globals;

%% Simulation
sim_file = pfullfile("sim", "sim_const");
vehicle_data = vehicle_params(doc);
brake_data = get_brake_data("ideal");

sim = doc.sims(1);
baseline = doc.simulate(sim, outputs = "ALL", stop = "APOGEE");
activation_point = find(baseline.("Mach number") >= 0.8, 1, "last");
altitude_values = linspace(baseline{activation_point, "Altitude"}, apogee_target-10, 20);

simin = structs2inputs(sim_file, vehicle_data);
simin = structs2inputs(simin, brake_data);
simin = simin.setVariable(t_0 = 0);
simin = simin.setVariable(dt = 1/100);
simin = simin.setModelParameter(SimulationMode = "accelerator", FastRestart = "on");

[upper, lower] = find_reachable_states(simin, apogee_target, altitude_values, ...
    baseline{activation_point, "Lateral velocity"});


% required every time model is
% initialized in Fast Restart, otherwise it needs to be manually disabled later
% to make parameter or model changes, which is annoying
set_param(simin.ModelName, FastRestart = "off"); 

%% Plots
figure(name = "Baseline phase plane");
hold on;
plot(altitude_values, upper);
plot(altitude_values, lower);
xlim([-Inf Inf]);
ylim([-Inf Inf]);

figure(name = "Varied horizontal velocity");
