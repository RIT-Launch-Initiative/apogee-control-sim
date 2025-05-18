clear;

sim_path = pfullfile("sim", "sim_actuator");
params = get_brake_data("noisy");
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


export_at_size(act_figure, "actuator_response.pdf", [500 220]);
