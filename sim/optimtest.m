clear;

rkt_file = pfullfile("data", "CRUD.ork");
sim_file = pfullfile("sim", "sim_2dof");
doc = openrocket(rkt_file);

vehicle_data = get_vehicle_data(doc);
data = doc.simulate(doc.sims(1), outputs = "ALL", stop = "BURNOUT");
inits = get_initial_data(data);
inits.dt = 0.01;

brake_off.control_mode = "const";
brake_off.const_brake = 0;

brake_on.control_mode = "const";
brake_on.const_brake = 0;

simin = struct2input(sim_file, vehicle_data);
simin = struct2input(simin, inits);

simin_off = struct2input(simin, struct(control_mode = "const", const_brake = 0));
simin_on = struct2input(simin, struct(control_mode = "const", const_brake = 1)); % max braking effort

simout_off = sim(simin_off);
simout_on = sim(simin_on);

target_apogee = 0.8 * (simout_off.apogee - simout_on.apogee) + simout_on.apogee; 
tic;
ext = find_extension(target_apogee, simin, 0.2);
time = toc;
fprintf("Finished optimization in %.2f sec\n", time);
fprintf("Maximum apogee: %.1f m\n", simout_off.apogee);
fprintf("Minimum apogee: %.1f m (maximum effort %.1f m)\n", ...
    simout_on.apogee, simout_off.apogee - simout_on.apogee)

simin_opt = struct2input(simin, struct(control_mode = "const", const_brake = ext));
simout_opt = sim(simin_opt);
fprintf("Targeted %.1f m, reached %.1f m with extension %.3f\n", ...
    target_apogee, simout_opt.apogee, ext);
