% clear;close all;
close all;
project_globals;

alt_p = baro_params("controls_module");
alt_p.GROUND_LEVEL = orkopts.getLaunchAltitude();

accel_p = accel_params("controls_module");
accel_p.GRAVITY = 9.81;
kalm_p = kalman_filter_params("alt-accel-bias");

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
simin = simin.setVariable(kalm_measure_cov = diag([0.23193856 0.0361]));
simin = simin.setModelParameter(SimulationMode = "accelerator", FastRestart = "on");

simout = sim(simin);
logs = extractTimetable(simout.logsout);

writematrix(["Time (s)" "Vertical acceleration (m/s²)" "Lateral acceleration (m/s²)" "Roll rate (rad/s)" "Pitch rate (rad/s)" "Yaw rate (rad/s)" "Air temperature (°C)" "Air pressure (mbar)";...
    seconds(logs.Time) logs.acceleration(:,2) -logs.acceleration(:,1) ...
    zeros([length(logs.acceleration) 1]) zeros([length(logs.acceleration) 1]) zeros([length(logs.acceleration) 1]) ...
    zeros([length(logs.acceleration) 1]) logs.pressure_meas/100],fullfile(launch_file,"testing","fake_flight_data.csv"),"WriteMode","overwrite");

set_param(simin.ModelName, FastRestart = "off");


% logs.

%     cost=0;
%     % cost=cost+rmse(logs_cut.position(:,2),logs_cut.altitude_est)*weights(1);
%     cost=cost+rmse(logs_cut.velocity(:,2),logs_cut.velocity_est)^2*weights(2);
%     cost=cost+rmse(logs_cut.acceleration(:,2),logs_cut.accel_est)*weights(3);
%     % cost=cost+abs(1-std(logs_cut.kalman_innov_norm(:,1)))*weights(4);
%     % cost=cost+abs(1-std(logs_cut.kalman_innov_norm(10:end,2)))*weights(5);
%     % cost = cost + max(abs(logs_cut.velocity(:,2)-logs_cut.velocity_est));
% 
%     alt_est(end+1,:)=logs.altitude_est;
%     alt_true(end+1,:)=logs.position(:,2);
% 
%     vel_est(end+1,:)=logs.velocity_est;
%     vel_true(end+1,:)=logs.velocity(:,2);
% 
%     accel_est(end+1,:)=logs.accel_est;
%     accel_true(end+1,:)=logs.acceleration(:,2);
% end




% %% Test
% 
% % close all;
% 
% Q=diag(table2array(results.XAtMinObjective));
% % Q=diag(10.^(QdB/10));
% % Q=diag([0.092021 1.96 3.7154 12.45]);
% R=diag([0.23193856 0.0361]);
% 
% simin=simin.setVariable(kalm_process_cov=Q);
% simin=simin.setVariable(kalm_measure_cov=R);
% 
% simout = sim(simin);
% logs = extractTimetable(simout.logsout);
% 
% t_true=logs.Time;
% alt_true=logs.position(:,2);
% vel_true=logs.velocity(:,2);
% accel_true=logs.acceleration(:,2);
% 
% alt_est=logs.altitude_est;
% vel_est=logs.velocity_est;
% accel_est=logs.accel_est;
% 
% figure(5);
% tiledlayout(3,2,"TileIndexing","columnmajor","TileSpacing","compact","Padding","compact");
% 
% nexttile;
% plot(t_true,alt_true);hold on;
% plot(t_true,alt_est);
% xline(time_to_burnout);
% title("Altitude");
% 
% nexttile;
% plot(t_true,vel_true);hold on;
% plot(t_true,vel_est);
% xline(time_to_burnout);
% title("Velocity");
% 
% nexttile;
% plot(t_true,accel_true,"DisplayName","True");hold on;
% plot(t_true,accel_est,"DisplayName","Estimated");
% xline(time_to_burnout,"DisplayName","Burnout");
% title("Acceleration");
% legend;
% 
% TR = timerange(duration(seconds(burnout_time)),duration(seconds(100)));
% logs_cut = logs(TR,:);
% 
% nexttile;
% plot(t_true,alt_est-alt_true);hold on;grid on;
% xline(time_to_burnout);
% yline([-5 5],"r--","LineWidth",1); % Good to have under
% title("Altitude Error");
% 
% nexttile;
% max_vel_error=max(abs(logs_cut.velocity_est-logs_cut.velocity(:,2)));
% plot(t_true,vel_est-vel_true);hold on;grid on;
% xline(time_to_burnout);
% yline([-3 3],"r--","LineWidth",1);
% title("Vel Error | Max Post Burn: "+string(round(max_vel_error,2))+"m/s");
% 
% nexttile;
% max_accel_error=max(abs(logs_cut.accel_est-logs_cut.acceleration(:,2)));
% plot(t_true,accel_est-accel_true);hold on;grid on;
% xline(time_to_burnout);
% yline([-3 3],"r--","LineWidth",1);
% ylim([-5 5])
% title("Accel Error | Max Post Burn: "+string(round(max_accel_error,2))+"m/s2");
% 
% 
% 
% figure(6);
% tiledlayout(2,1,"TileIndexing","columnmajor","TileSpacing","compact","Padding","compact");
% 
% nexttile;
% plot(t_true,logs.kalman_innov_norm(:,1));xline(burnout_time);
% ylim([-4 4]);yline([-3 3],"r--","LineWidth",1);
% title("Barometer Norm Innov | Std: "+string(round(std(logs.kalman_innov_norm(:,1)),2)));
% 
% nexttile;
% plot(t_true,logs.kalman_innov_norm(:,2));xline(burnout_time);
% ylim([-4 4]);yline([-3 3],"r--","LineWidth",1);
% title("Accelerometer Norm Innov | Std: "+string(round(std(logs.kalman_innov_norm(4:end,2)),2)));
















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
%         params = kalman_filter_params("alt-accel-bias");
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