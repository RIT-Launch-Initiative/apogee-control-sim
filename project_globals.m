%% DEFINE PROJECT GLOBALS
% OpenRocket document definitions
rkt_file = pfullfile("data", "OMEN.ork"); % path to OpenRocket file
sim_name = "MATLAB"; % name of "nominal case" simulation

% Cache for generated lookup tables
luts_file = pfullfile("data", "lutdata.mat");

% Cache for large Monte Carlo runs
runs_file = pfullfile("data", "rundata.mat");

% Create objects from names and paths
doc = openrocket(rkt_file);
orksim = doc.sims(sim_name);
orkopts = orksim.getOptions(); 
luts = matfile(luts_file, Writable = true);
runs = matfile(runs_file, Writable = true); 

% Magic numbers
vel_max = 270; % [m/s] approximate velocity for 0.8Ma
alt_start = 1200; % [m] approximate altitude at which rocket falls below 0.8Ma
apogee_target = 3300; % [m] altitude we are targeting
