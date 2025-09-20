%% DEFINE PROJECT GLOBALS

% Rocket Selection
option = 3;

% Switch case to select the rocket file and the correct nominal case
switch option
    case 1
        rocket_file = "IREC-2026-4U.ork";
        sim_name = "15mph-Midland-N2220";
        vel_max = 240; % [m/s] approximate velocity for 0.8Ma
        alt_start = 830; % [m] approximate altitude at which rocket falls below 0.8Ma
        apogee_target = 3048; % [m] altitude we are targeting (10,000ft)
    case 2
        rocket_file = "IREC-2026-4U.ork";
        sim_name = "15mph-Midland-N3800-Loki";
        vel_max = 260;
        alt_start = 1300;
        apogee_target = 3048;
    case 3
        rocket_file = "IREC-2026-4U.ork";
        sim_name = "15mph-Midland-N3300";
        vel_max = 255;
        alt_start = 1900;
        apogee_target = 3048;
    case 4
        rocket_file = "IREC-2026-4U.ork";
        sim_name = "15mph-Midland-N2700-AMW";
        vel_max = 260;
        alt_start = 885;
        apogee_target = 3048;
    case 5
        rocket_file = "IREC-2026-4U.ork";
        sim_name = "15mph-Midland-N2000";
        vel_max = 260;
        alt_start = 1570;
        apogee_target = 3048;
    case 6
        rocket_file = "IREC-2026-4U.ork";
        sim_name = "15-Midland-N10000-CTI";
        vel_max = 270;
        alt_start = 570;
        apogee_target = 3048;
    case 7
        rocket_file = "OMEN.ork";
        sim_name = "MATLAB";
        vel_max = 270;
        alt_start = 1200;
        apogee_target = 3300;
    case 8
        rocket_file = "TB-1.ork";
        sim_name = "MATLAB";
        vel_max = 195;
        alt_start = 430;
        apogee_target = 1350;
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