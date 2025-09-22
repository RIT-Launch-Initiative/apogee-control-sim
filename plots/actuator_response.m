clear;
project_globals;

sim_path = pfullfile("sim", "sim_actuator");
params = vehicle_params("openrocket", rocket_file, sim_name); % this includes actuator dynamics
simin = structs2inputs(sim_path, params);
simout = sim(simin);
logs = extractTimetable(simout.logsout);

act_figure = figure(name = "Actuator response");
hold on; grid on;
plot(logs.Time, logs.effort, DisplayName = "Effort");
plot(logs.Time, logs.extension, DisplayName = "Response");
ylabel("Fraction");
xlabel("Time");
legend;


print2size(act_figure, fullfile(graphics_path, "actuator_response.pdf"), [800 350]);
