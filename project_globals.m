%% DEFINE PROJECT GLOBALS

% Rocket Selection
rkt_option = 4;

% Switch case to select the rocket file and the correct nominal case
switch rkt_option
    case 1
        rocket_file = "OMEN.ork";
        sim_name = "MATLAB";
        apogee_target = 3300; % [m] altitude we are targeting (10,000ft)
    case 2
        rocket_file = "TB-1.ork";
        sim_name = "15mph_URRG";
        apogee_target = 1350; % [m]
    case 3
        rocket_file = "IREC-2026-M3400.ork";
        sim_name = "15mph-Midland";
        apogee_target = 3048; % [m]
    case 4
        rocket_file = "IREC-2026-N3800.ork";
        sim_name = "15mph-Midland";
        apogee_target = 3048; % [m]
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

% Get custom atmosphere model
load("21-Jun-2025-10.21.00-midland-gfs_1.mat")
airdata.TMP = airdata.TMP + 273.15; % Convert C to K

% Get vel & alt at the time when airbrakes can first extend, following DTEG rules
orkdata = doc.simulate(orksim, outputs = "ALL", stop = "APOGEE", atmos = airdata);
mach_at_burnout = orkdata{eventfilter("BURNOUT"), "Mach number"};
if mach_at_burnout >= 0.8
    % Determined by when rocket is less than mach 0.8
    orkdata_burnout_to_apogee = orkdata(timerange(eventfilter("BURNOUT"), eventfilter("APOGEE")),:);
    index_to_mach = find(orkdata_burnout_to_apogee.("Mach number") < 0.8, 1, "first");
    time_to_mach = orkdata_burnout_to_apogee.Properties.RowTimes(index_to_mach);
    vel_max = orkdata{time_to_mach, "Vertical velocity"};
    alt_start = orkdata{time_to_mach, "Altitude"};
    clear orkdata_burnout_to_apogee index_to_mach time_to_mach
else
    % Determined by motor burnout
    vel_max = orkdata{eventfilter("BURNOUT"), "Vertical velocity"}; % Velocity for 0.8Ma
    alt_start = orkdata{eventfilter("BURNOUT"), "Altitude"}; % Altitude at which rocket falls below 0.8Ma
end
clear orkdata mach_at_burnout