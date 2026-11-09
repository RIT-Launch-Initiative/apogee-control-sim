%% DEFINE PROJECT GLOBALS

% Rocket Selection
rkt_option = 3;

% Switch case to select the rocket file and the correct nominal case
switch rkt_option
    case 1
        rocket_file = "TB-1.ork";
        sim_name = "15mph_URRG";
    case 2
        rocket_file = "RISK.ork";
        sim_name = "15mph-Midland";
    case 3
        rocket_file = "BIRD_11-7.ork";
        sim_name = "15mph-Midland";
    otherwise
        error('Invalid rocket file option')
end

% OpenRocket document definitions
rkt_file = pfullfile("data", rocket_file); % path to OpenRocket file

% Cache for generated lookup tables
luts_file = pfullfile("data", "lutdata.mat");

% Cache for large Monte Carlo runs
runs_file = pfullfile("data", "rundata.mat");

% Cache for atmosphere data
airs_file = pfullfile("data", "airdata.mat");

% Where plots go by default
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
airs = matfile(airs_file, Writable = true);

% Get custom atmosphere model
load("16-Jun-2025-11.0.0-spaceport-midland-nam")
airdata.TMP = airdata.TMP + 273.15; % Convert C to K

generate_target;

% Get vel & alt at the time when airbrakes can first extend, following DTEG rules
orkdata_for_flight_metadata = doc.simulate(orksim, outputs = "ALL", stop = "APOGEE", atmos = airdata);
mach_at_burnout = orkdata_for_flight_metadata{eventfilter("BURNOUT"), "Mach number"};
if mach_at_burnout >= 0.8
    % Determined by when rocket is less than mach 0.8
    orkdata_burnout_to_apogee = orkdata_for_flight_metadata(timerange(eventfilter("BURNOUT"), eventfilter("APOGEE")),:);
    index_to_mach = find(orkdata_burnout_to_apogee.("Mach number") < 0.8, 1, "first");
    time_to_mach = orkdata_burnout_to_apogee.Properties.RowTimes(index_to_mach);
    vel_max = orkdata_for_flight_metadata{time_to_mach, "Vertical velocity"};
    alt_start = orkdata_for_flight_metadata{time_to_mach, "Altitude"};
    time_start = seconds(time_to_mach);
    clear orkdata_burnout_to_apogee index_to_mach time_to_mach
else
    % Determined by motor burnout
    vel_max = orkdata_for_flight_metadata{eventfilter("BURNOUT"), "Vertical velocity"}; % Velocity for 0.8Ma
    alt_start = orkdata_for_flight_metadata{eventfilter("BURNOUT"), "Altitude"}; % Altitude at which rocket falls below 0.8Ma
    time_start = seconds(orkdata_for_flight_metadata.Time(eventfilter("BURNOUT")));
end
clear orkdata_for_flight_metadata mach_at_burnout