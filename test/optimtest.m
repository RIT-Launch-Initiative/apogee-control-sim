clear;

project_globals;
% configure simulation
sim_file = pfullfile("sim", "sim_const"); % more efficient sim for 
vehicle_data = vehicle_params(doc);
data = doc.simulate(doc.sims(1), outputs = "ALL", stop = "BURNOUT");
inits = get_initial_data(data);

simin = structs2inputs(sim_file, vehicle_data);
simin = structs2inputs(simin, inits);

simin_off = simin.setVariable(const_brake = 0);
simin_on = simin.setVariable(const_brake = 1);

simout_off = sim(simin_off);
simout_on = sim(simin_on);

target_apogee = 0.8 * (simout_off.apogee - simout_on.apogee) + simout_on.apogee; 
tic;
% set up for rapid re-simulation
simin = simin.setModelParameter(FastRestart = "on", SimulationMode = "accelerator");
ext = find_extension(target_apogee, simin, 0.2);
time = toc;

fprintf("Finished optimization in %.2f sec\n", time);
fprintf("Maximum apogee: %.1f m\n", simout_off.apogee);
fprintf("Minimum apogee: %.1f m (maximum effort %.1f m)\n", ...
    simout_on.apogee, simout_off.apogee - simout_on.apogee)

simin_opt = structs2inputs(simin, struct(control_mode = "const", const_brake = ext));
simout_opt = sim(simin_opt);

fprintf("Targeted %.1f m, reached %.1f m with extension %.3f\n", ...
    target_apogee, simout_opt.apogee, ext);

set_param(simin.ModelName, FastRestart = "off");
