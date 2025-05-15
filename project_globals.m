rkt_file = pfullfile("data", "OMEN.ork");
sim_file = pfullfile("sim", "sim_2dof");
luts_file = pfullfile("data", "tables.mat");
data_file = pfullfile("data", "imports.mat");

doc = openrocket(rkt_file);
simin = Simulink.SimulationInput(sim_file);
luts = matfile(luts_file, Writable = true);
imports = matfile(data_file, Writable = false);

apogee_target = 3048;

