%% DEFINE PROJECT GLOBALS

launch_name = "testbed";

launch_file = pfullfile("launches", launch_name);
rocket_file = string(dir(fullfile(launch_file,"openrocket","*.ork")).name);
rkt_file = fullfile(launch_file,"openrocket",rocket_file);
luts_file = fullfile(launch_file,"cached","lutdata.mat");
runs_file = fullfile(launch_file,"cached","rundata.mat");
run(fullfile(launch_file,"target","target.m"));
flight_info_file = fullfile(launch_file,"cached","flight_info.mat");

use_custom_atm = true;
atm_file = fullfile(launch_file,"atmosphere",string(dir(fullfile(launch_file,"atmosphere","*.mat")).name));
load(atm_file);
airdata.TMP = airdata.TMP + 273.15; % Convert C to K
PRES = interp1(airdata.HGT,airdata.PRES,[0;airdata.HGT],"linear","extrap");
HGT = [0;airdata.HGT];
TMP = [airdata.TMP(1);airdata.TMP];
UGRD = [airdata.UGRD(1);airdata.UGRD];
VGRD = [airdata.VGRD(1);airdata.VGRD];
airdata = table(PRES,HGT,TMP,UGRD,VGRD);
clear PRES HGT TMP UGRD VGRD;

% % Rocket Selection
% rkt_option = 3;
%
% % Switch case to select the rocket file and the correct nominal case
% switch rkt_option
%     case 1
%         rocket_file = "OMEN.ork";
%         sim_name = "MATLAB";
%         apogee_target = 3300; % [m] altitude we are targeting (10,000ft)
%     case 2
%         rocket_file = "TB-1.ork";
%         sim_name = "15mph_URRG";
%         apogee_target = 1200; % [m]
%     case 3
%         rocket_file = "RISK.ork";
%         sim_name = "15mph-Midland";
%         apogee_target = 3048; % [m]
%     case 4
%         rocket_file = "L1 Kit.ork";
%         sim_name = "Simulation 1";
%         apogee_target = 700; % [m]
%     otherwise
%         error('Invalid rocket file option')
% end
% 
% % OpenRocket document definitions
% rkt_file = pfullfile("data", rocket_file); % path to OpenRocket file
% 
% % Cache for generated lookup tables
% luts_file = pfullfile("data", "lutdata.mat");
% 
% % Cache for large Monte Carlo runs
% runs_file = pfullfile("data", "rundata.mat");

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

% % Get custom atmosphere model
% load("21-Jun-2025-10.21.00-midland-gfs_1.mat")
% airdata.TMP = airdata.TMP + 273.15; % Convert C to K
% % airdata = airdata(:, ["HGT", "PRES", "TMP"]); % TESTING

% Get vel & alt at the time when airbrakes can first extend, following DTEG rules
if ~isfile(flight_info_file)
    if use_custom_atm
        orkdata = doc.simulate(orksim, outputs = "ALL", atmos = airdata);
    else
        orkdata = doc.simulate(orksim, outputs = "ALL");
    end
    mach_at_burnout = orkdata{eventfilter("BURNOUT"), "Mach number"};
    if mach_at_burnout >= 0.8
        % Determined by when rocket is less than mach 0.8
        orkdata_burnout_to_apogee = orkdata(timerange(eventfilter("BURNOUT"), eventfilter("APOGEE")),:);
        index_to_mach = find(orkdata_burnout_to_apogee.("Mach number") < 0.8, 1, "first");
        time_to_mach = orkdata_burnout_to_apogee.Properties.RowTimes(index_to_mach);
        vel_max = orkdata{time_to_mach, "Vertical velocity"}; % Velocity for 0.8Ma
        alt_start = orkdata{time_to_mach, "Altitude"}; % Altitude at which rocket falls below 0.8Ma
        clear orkdata_burnout_to_apogee index_to_mach time_to_mach
    else
        % Determined by motor burnout
        vel_max = orkdata{eventfilter("BURNOUT"), "Vertical velocity"};
        alt_start = orkdata{eventfilter("BURNOUT"), "Altitude"};
    end
    % vel_max = vel_max - 0; % Helps if typical_variation fails from not finding start time
    time_to_burnout = seconds(orkdata.Properties.Events.Time(orkdata.Properties.Events.EventLabels == "BURNOUT"));
    time_to_sim_end = seconds(orkdata.Properties.Events.Time(orkdata.Properties.Events.EventLabels == "SIMULATION_END" ));
    clear orkdata mach_at_burnout

    save(fullfile(launch_file, "cached", "flight_info.mat"), "vel_max", "alt_start", "time_to_burnout", "time_to_sim_end");
else
    load(flight_info_file);
end

turn_off_extension = 0;