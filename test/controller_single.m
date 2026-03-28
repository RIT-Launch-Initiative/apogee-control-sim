% close all;

% clear;
project_globals;

sensor_mode = "noisy";
% sensor_mode = "ideal";

% filt_under_test = "butter";
filt_under_test = "kalman";

% ctrl_under_test = "exhaust";
ctrl_under_test = "quantile_effort";
% ctrl_under_test = "s_function";

simin = Simulink.SimulationInput("sim_controller");

if use_custom_atm
    orkdata = doc.simulate(doc.sims(sim_name), outputs = "ALL", stop = "APOGEE", atmos = airdata);
else
    orkdata = doc.simulate(doc.sims(sim_name), outputs = "ALL", stop = "APOGEE");
end
inits = get_initial_data(orkdata);

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
        params = kalman_filter_params("alt-accel-bias");
        % the initial state is not likely to be perfect, but this is more
        % realistic than using all-zeros 
        initdata = retime(orkdata, seconds(inits.t_0));
        params.kalm_initial = [initdata.Altitude; 
            initdata.("Vertical velocity");
            initdata.("Vertical acceleration");
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

simin = structs2inputs(simin, vehicle_params("openrocket", rkt_file, sim_name));
simin = structs2inputs(simin, inits);
simin = simin.setVariable(dt = 0.01);

simout = sim(simin);
logs = extractTimetable(simout.logsout);
logs = fillmissing(logs, "previous");

% plot setup
true_args = {"DisplayName", "True"};
meas_args = {"DisplayName", "Measured"};
est_args = {"DisplayName", "Estimated"};

figure(name = "State estimation");
layout = tiledlayout(3,2);
layout.TileIndexing = "rowmajor";

nexttile; hold on; grid on;
plot(logs.Time, logs.position(:,2), true_args{:});
plot(logs.Time, logs.altitude_meas, meas_args{:});
plot(logs.Time, logs.altitude_est, est_args{:});
ylabel("Altitude");
ysecondarylabel("m AGL");

nexttile; hold on; grid on;
plot(logs.Time, logs.altitude_est - logs.position(:,2));
ylabel("Error");
ysecondarylabel("m");

nexttile; hold on; grid on;
plot(logs.Time, logs.velocity(:,2), true_args{:});
plot(logs.Time, logs.velocity_meas, meas_args{:}); %
plot(logs.Time, logs.velocity_est, est_args{:});
ylabel("Vertical velocity");
ysecondarylabel("m/s");

nexttile; hold on; grid on;
plot(logs.Time, logs.velocity_est - logs.velocity(:,2));
ylabel("Error");
ysecondarylabel("m/s");

nexttile; hold on; grid on;
plot(logs.Time, logs.acceleration(:,2), true_args{:});
plot(logs.Time, logs.accel_meas, meas_args{:});
plot(logs.Time, logs.accel_est, est_args{:});
ylabel("Vertical acceleration");
ysecondarylabel("m/s^2");
xlabel("Time");

legend;

nexttile; hold on; grid on;
plot(logs.Time, logs.accel_est - logs.acceleration(:,2));
ylabel("Error");
ysecondarylabel("m/s^2");
xlabel("Time");


figure(name = "Effort history");
layout = tiledlayout(3,1);

nexttile([2 1]); hold on; grid on;
plot(logs.position(:,2), logs.velocity(:,2), true_args{:});
plot(logs.altitude_est, logs.velocity_est, est_args{:});
xlabel("Altitude");
xsecondarylabel("m AGL");
ylabel("Vertical velocity");
ysecondarylabel("m/s");
legend;

nexttile; hold on; grid on;
plot(logs.Time, logs.effort, "--", SeriesIndex = 1, DisplayName = "Controller effort");
plot(logs.Time, logs.extension, "-", SeriesIndex = 1, DisplayName = "Extension"); %
legend;
ylabel("Airbrake extension");
xlabel("Time");





% Aiden stuff
% figure();
% layout = tiledlayout(2,1,"TileSpacing","compact","Padding","compact");
% layout.TileIndexing = "rowmajor";
% sgtitle("Innovation");
% nexttile;plot(logs.Time,logs.v_innovation(:,1));title("Altitude");grid on;
% nexttile;plot(logs.Time,logs.v_innovation(:,2));title("Acceleration");grid on;
% 
% figure();
% layout = tiledlayout(2,1,"TileSpacing","compact","Padding","compact");
% layout.TileIndexing = "rowmajor";
% sgtitle("Normalized Innovation");
% nexttile;plot(logs.Time,logs.innovation_norm(:,1));title("Altitude");hold on;grid on;
% yline([-3 3],"r--","LineWidth",1);
% ylabel("(-)");
% ylim([-4 4]);
% legend("","3σ")
% nexttile;plot(logs.Time,logs.innovation_norm(:,2));title("Acceleration");hold on;grid on;
% yline([-3 3],"r--","LineWidth",1);
% ylabel("(-)");
% ylim([-4 4]);
% 
% figure();
% layout = tiledlayout(2,1,"TileSpacing","compact","Padding","compact");
% layout.TileIndexing = "rowmajor";
% sgtitle("Autocorrelation");
% [r,lags]=xcorr(logs.v_innovation(:,1),"normalized");
% r=r(lags>=0);lags=lags(lags>=0);
% nexttile;plot(lags,r);title("Altitude");hold on;grid on;
% yline([-1.96/sqrt(length(logs.Time)) 1.96/sqrt(length(logs.Time))],"r--","LineWidth",1);
% [r,lags]=xcorr(logs.v_innovation(:,2),"normalized");
% r=r(lags>=0);lags=lags(lags>=0);
% nexttile;plot(lags,r);title("Acceleration");hold on;grid on;
% yline([-1.96/sqrt(length(logs.Time)) 1.96/sqrt(length(logs.Time))],"r--","LineWidth",1);







% set(gcf,"Position",[0 0 400 300]);

% Closes all simulink models after running
% Fixes some errors if you need to regenerate data
bdclose('all')



% figure();
% plot(logs.Time,logs.process_difference,"LineWidth",1);
% legend("Alt","Vel","Accel");