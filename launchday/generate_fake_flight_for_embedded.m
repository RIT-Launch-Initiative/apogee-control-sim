% clear;close all;
close all;
project_globals;

alt_p = baro_params("controls_module");
alt_p.GROUND_LEVEL = orkopts.getLaunchAltitude();

accel_p = accel_params("controls_module");
accel_p.GRAVITY = 9.81;
kalm_p = kalman_filter_params("alt-accel-bias",launch_file);

% orkopts.setLaunchRodAngle(deg2rad(20));
if use_custom_atm
    orkdata = doc.simulate(orksim, outputs = "ALL", stop = "APOGEE", atmos = airdata);
else
    orkdata = doc.simulate(orksim, outputs = "ALL", stop = "APOGEE");
end
orkdata = fillmissing(orkdata, "previous");

global burnout_time;
burnout_time = seconds(orkdata.Properties.Events.Time(orkdata.Properties.Events.EventLabels == "BURNOUT"));

inputs.t_0 = seconds(orkdata.Time(1));
inputs.t_f = seconds(orkdata.Time(end));
inputs.dt = 1/kalm_p.input_rate;

inputs.position = timeseries(orkdata{:, ["Lateral distance", "Altitude"]}, ...
    seconds(orkdata.Time));
inputs.accel = timeseries(orkdata{:, ["Lateral acceleration", "Vertical acceleration"]}, ...
    seconds(orkdata.Time));
inputs.pitch = orkdata(:, "Vertical orientation (zenith)");

simin = structs2inputs(pfullfile("sim", "sim_kalman"), kalm_p, alt_p, accel_p);
simin = structs2inputs(simin, inputs);

load(fullfile(launch_file,"tune","tune.mat"));

simin = simin.setVariable(kalm_process_cov = diag(variances));
simin = simin.setVariable(kalm_measure_cov = diag([0.061410353 2.3659593e-05]));
simin = simin.setModelParameter(SimulationMode = "accelerator", FastRestart = "on");

simout = sim(simin);
logs = extractTimetable(simout.logsout);

writematrix(["# Time (s)" "Vertical acceleration (m/s²)" "Lateral acceleration (m/s²)" "Roll rate (rad/s)" "Pitch rate (rad/s)" "Yaw rate (rad/s)" "Air temperature (°C)" "Air pressure (mbar)";...
    seconds(logs.Time) logs.acceleration(:,2) -logs.acceleration(:,1) ...
    zeros([length(logs.acceleration) 1]) zeros([length(logs.acceleration) 1]) zeros([length(logs.acceleration) 1]) ...
    zeros([length(logs.acceleration) 1]) logs.pressure_meas/100],fullfile(launch_file,"testing","fake_flight_data.csv"),"WriteMode","overwrite");

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
% simin = structs2inputs(simin, vehicle_params("openrocket", rkt_file, sim_name));
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