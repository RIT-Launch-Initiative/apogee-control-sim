% close all;

% clear;
project_globals;

turn_off_extension = 0;

sensor_mode = "noisy";
% sensor_mode = "ideal";

% filt_under_test = "butter";
filt_under_test = "kalman";

% ctrl_under_test = "exhaust";
ctrl_under_test = "quantile_effort";
% ctrl_under_test = "s_function";

simin = Simulink.SimulationInput("sim_controller");

orkopts.setWindSpeedAverage(7);
orkopts.setWindSpeedDeviation(3)
orkopts.setTimeStep(0.05);
orkopts.setLaunchRodAngle(deg2rad(10));
orkopts.setWindDirection(deg2rad(0));
orkopts.setLaunchTemperature(293);

if use_custom_atm
    orkdata = doc.simulate(doc.sims(sim_name), outputs = "ALL", stop = "APOGEE", atmos = airdata);
else
    orkdata = doc.simulate(doc.sims(sim_name), outputs = "ALL", stop = "APOGEE");
end
inits = get_initial_data(orkdata);

burnout_time = inits.t_0;

switch sensor_mode
    case "noisy"
        simin = structs2inputs(simin, accel_params("controls_module"));
        simin = structs2inputs(simin, baro_params("controls_module"));
    case "ideal"
        simin = structs2inputs(simin, accel_params("ideal"));
        simin = structs2inputs(simin, baro_params("ideal"));
    otherwise
        error ("Unrecognzied case %s", sensor_mode);
end

switch filt_under_test
    case "butter"
        simin = simin.setVariable(filter_mode = "butter");
        simin = structs2inputs(simin, alt_filter_params("designed"));
        simin = structs2inputs(simin, accel_filter_params("designed"));
    case "kalman"
        params = kalman_filter_params("alt-accel-bias",launch_file);
        % the initial state is not likely to be perfect, but this is more
        % realistic than using all-zeros 
        initdata = retime(orkdata, seconds(inits.t_0));
        % params.kalm_initial = [initdata.Altitude; 
        %     initdata.("Vertical velocity");
        %     initdata.("Vertical acceleration");
        %     9.81];
        params.kalm_initial = [initdata.Altitude;% + 500*(rand()-0.5); 
            initdata.("Vertical velocity");% + 150*(rand()-0.5);
            initdata.("Vertical acceleration");% + 20*(rand()-0.5);
            9.81];

        simin = simin.setVariable(filter_mode = "kalman");
        simin = structs2inputs(simin, params);

    otherwise
        error ("Unrecognzied case %s", filt_under_test);
end

switch ctrl_under_test
    case "exhaust"
        if isfile(luts_file)
            % Preloads the lookup table if it is available
            lookups = matfile(luts_file, Writable = false);
        else
            generate_luts; % Generates the lookup table
            lookups = matfile(luts_file, Writable = false);
        end

        simin = simin.setVariable(controller_rate = 100); %10
        simin = simin.setVariable(control_mode = "exhaust");
        simin = simin.setVariable(baro_lut = ...
            xarray2lut(lookups.exhaust_100_by_100, ["vel", "alt"]));
    case "quantile_effort"
        % loads the .mat file if is exists, otherwise it generates it
        if isfile(luts_file)
            % Preloads the lookup table if it is available
            lookups = matfile(luts_file, Writable = false);
        else
            generate_quant_luts; % Generates the quantile lookup table
            lookups = matfile(luts_file, Writable = false);
        end

        simin = simin.setVariable(controller_rate = 100); %10
        simin = simin.setVariable(control_mode = "quant");
        simin = simin.setVariable(lower_bound_lut = ...
            xarray2lut(lookups.lower_bounds, "alt"));
        simin = simin.setVariable(upper_bound_lut = ...
            xarray2lut(lookups.upper_bounds, "alt"));
    case "s_function"
        simin = simin.setVariable(controller_rate = 10);
        simin = simin.setVariable(control_mode = "s");
    otherwise
        error ("Unrecognzied case %s", ctrl_under_test);
end

simin = structs2inputs(simin, vehicle_params("openrocket", rkt_file, sim_name, drag_file));
simin = structs2inputs(simin, inits);
simin = simin.setVariable(dt = 0.01);

simout = sim(simin);
logs = extractTimetable(simout.logsout);
logs = fillmissing(logs, "previous");

plot(seconds(logs.Time),logs.effort);
ylim([0 1]);

TR = timerange(seconds(0),seconds(burnout_time));
orkdata = orkdata(TR,:);

TR = timerange(seconds(burnout_time),seconds(100));
logs = logs(TR,:);

writematrix(["# Time (s)" "Vertical acceleration (m/s²)" "Lateral acceleration (m/s²)" "Roll rate (rad/s)" "Pitch rate (rad/s)" "Yaw rate (rad/s)" "Air temperature (°C)" "Air pressure (kPa)" "Shenanigans (sqrt_Hz)";...
    [seconds(orkdata.Time); seconds(logs.Time)] [orkdata{:,"Vertical acceleration"}; logs.acceleration(:,2)] [orkdata{:,"Lateral acceleration"}; -logs.acceleration(:,1)] ...
    [zeros([length(orkdata.Time) 1]); zeros([length(logs.acceleration) 1])] [zeros([length(orkdata.Time) 1]); zeros([length(logs.acceleration) 1])] [zeros([length(orkdata.Time) 1]); zeros([length(logs.acceleration) 1])] ...
    [zeros([length(orkdata.Time) 1]); zeros([length(logs.acceleration) 1])] [orkdata{:,"Air pressure"}./1000; logs.pressure_meas./1000] [orkdata{:,"Vertical velocity"}; logs.velocity_est]],fullfile(launch_file,"testing","fake_flight_data.csv"),"WriteMode","overwrite");

set_param(simin.ModelName, FastRestart = "off");


















%% Maybe could use the fully controlled sim below
%  and even though the embedded controller can't affect it's world,
%  but if everything works then the effort it gives should match matlab
% 
% % clear;
% project_globals;
% 
% sensor_mode = "noisy";
% % sensor_mode = "ideal";
% 
% % filt_under_test = "butter";
% filt_under_test = "kalman";
% 
% % ctrl_under_test = "exhaust";
% ctrl_under_test = "quantile_effort";
% % ctrl_under_test = "s_function";
% 
% simin = Simulink.SimulationInput("sim_controller");
% 
% if use_custom_atm
%     orkdata = doc.simulate(doc.sims(sim_name), outputs = "ALL", stop = "APOGEE", atmos = airdata);
% else
%     orkdata = doc.simulate(doc.sims(sim_name), outputs = "ALL", stop = "APOGEE");
% end
% inits = get_initial_data(orkdata);
% 
% switch sensor_mode
%     case "noisy"
%         simin = structs2inputs(simin, accel_params("controls_module"));
%         simin = structs2inputs(simin, baro_params("controls_module"));
%     case "ideal"
%         simin = structs2inputs(simin, accel_params("ideal"));
%         simin = structs2inputs(simin, baro_params("ideal"));
%     otherwise
%         error ("Unrecognzied case %s", sensor_mode);
% end
% 
% switch filt_under_test
%     case "butter"
%         simin = simin.setVariable(filter_mode = "butter");
%         simin = structs2inputs(simin, alt_filter_params("designed"));
%         simin = structs2inputs(simin, accel_filter_params("designed"));
%     case "kalman"
%         params = kalman_filter_params("alt-accel-bias",launch_file);
%         % the initial state is not likely to be perfect, but this is more
%         % realistic than using all-zeros 
%         initdata = retime(orkdata, seconds(inits.t_0));
%         params.kalm_initial = [initdata.Altitude; 
%             initdata.("Vertical velocity");
%             initdata.("Vertical acceleration");
%             9.81];
% 
%         simin = simin.setVariable(filter_mode = "kalman");
%         simin = structs2inputs(simin, params);
% 
%     otherwise
%         error ("Unrecognzied case %s", filt_under_test);
% end
% 
% switch ctrl_under_test
%     case "exhaust"
%         if isfile(luts_file)
%             % Preloads the lookup table if it is available
%             lookups = matfile(luts_file, Writable = false);
%         else
%             generate_luts; % Generates the lookup table
%             lookups = matfile(luts_file, Writable = false);
%         end
% 
%         simin = simin.setVariable(controller_rate = 100); %10
%         simin = simin.setVariable(control_mode = "exhaust");
%         simin = simin.setVariable(baro_lut = ...
%             xarray2lut(lookups.exhaust_100_by_100, ["vel", "alt"]));
%     case "quantile_effort"
%         % loads the .mat file if is exists, otherwise it generates it
%         if isfile(luts_file)
%             % Preloads the lookup table if it is available
%             lookups = matfile(luts_file, Writable = false);
%         else
%             generate_quant_luts; % Generates the quantile lookup table
%             lookups = matfile(luts_file, Writable = false);
%         end
% 
%         simin = simin.setVariable(controller_rate = 100); %10
%         simin = simin.setVariable(control_mode = "quant");
%         simin = simin.setVariable(lower_bound_lut = ...
%             xarray2lut(lookups.lower_bounds, "alt"));
%         simin = simin.setVariable(upper_bound_lut = ...
%             xarray2lut(lookups.upper_bounds, "alt"));
%     case "s_function"
%         simin = simin.setVariable(controller_rate = 10);
%         simin = simin.setVariable(control_mode = "s");
%     otherwise
%         error ("Unrecognzied case %s", ctrl_under_test);
% end
% 
% simin = structs2inputs(simin, vehicle_params("openrocket", rkt_file, sim_name, drag_file));
% simin = structs2inputs(simin, inits);
% simin = simin.setVariable(dt = 0.01);
% 
% simout = sim(simin);
% logs = extractTimetable(simout.logsout);
% logs = fillmissing(logs, "previous");
% 
% % plot setup
% true_args = {"DisplayName", "True"};
% meas_args = {"DisplayName", "Measured"};
% est_args = {"DisplayName", "Estimated"};
% 
% figure(name = "State estimation");
% layout = tiledlayout(3,2);
% layout.TileIndexing = "rowmajor";