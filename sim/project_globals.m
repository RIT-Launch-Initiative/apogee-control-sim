rkt_file = pfullfile("data", "CRUD.ork");
sim_file = pfullfile("sim", "sim_2dof");
luts_file = pfullfile("data", "tables.mat");

doc = openrocket(rkt_file);
simin = Simulink.SimulationInput(sim_file);
luts = matfile(luts_file, Writable = true);
