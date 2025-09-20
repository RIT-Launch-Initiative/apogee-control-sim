%% DEFINE PROJECT GLOBALS

% Rocket Selection
option = 1;

% Switch case to select the rocket file and the correct nominal case
switch option
    case 1
        rocket_file = "IREC-2026-4U.ork";
        sim_name = "Baseline";
    case 2
        rocket_file = "OMEN.ork";
        sim_name = "MATLAB";
    case 3
        rocket_file = "TB-1.ork";
        sim_name = "MATLAB";
    otherwise
        error('Invalid rocket file option')
end

% OpenRocket document definitions
rkt_file = pfullfile("data", rocket_file); % path to OpenRocket file

% Cache for generated lookup tables
luts_file = pfullfile("data", "lutdata.mat");

% Cache for large Monte Carlo runs
runs_file = pfullfile("data", "rundata.mat");

% where plots go by default
graphics_path = pfullfile("refs", "report", "assets");
if ~isfolder(graphics_path)
    graphics_path = pfullfile("plots");
end

% Create objects from names and paths
doc = openrocket(rkt_file);
orksim = doc.sims(sim_name);
orkopts = orksim.getOptions(); 
luts = matfile(luts_file, Writable = true);
runs = matfile(runs_file, Writable = true); 

%% Magic numbers
vel_max = 190; % [m/s] approximate velocity for 0.8Ma
alt_start = 420; % [m] approximate altitude at which rocket falls below 0.8Ma
apogee_target = 3048; % [m] altitude we are targeting (10,000ft)
