% clear;close all;
% close;
project_globals;

alt_p = baro_params("controls_module");
alt_p.GROUND_LEVEL = orkopts.getLaunchAltitude();

accel_p = accel_params("controls_module");
accel_p.GRAVITY = 9.81;
kalm_p = kalman_filter_params("alt-accel-bias",launch_file);

orkopts.setLaunchRodAngle(deg2rad(10));

orkopts.setWindSpeedAverage(7);
orkopts.setWindSpeedDeviation(3)
orkopts.setTimeStep(0.05);

if use_custom_atm
    orkdata = doc.simulate(orksim, outputs = "ALL", stop = "APOGEE", atmos = airdata);
else
    orkdata = doc.simulate(orksim, outputs = "ALL", stop = "APOGEE");
end
orkdata = fillmissing(orkdata, "previous");

global burnout_time;
burnout_time = seconds(orkdata.Properties.Events.Time(orkdata.Properties.Events.EventLabels == "BURNOUT"));

% TR = timerange(duration(seconds(burnout_time)),duration(seconds(100)));
% orkdata = orkdata(TR,:);

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

num_solver_steps = 150;

% Optimize

if ~exist("Q","var")
    simin = simin.setVariable(kalm_process_cov = diag([1e-4 1e-4 20e-1 1e-1]));
    simin = simin.setVariable(kalm_measure_cov = diag([0.061410353 2.3659593e-05]));

    simin = simin.setModelParameter(SimulationMode = "accelerator", FastRestart = "on");
    
    Q1=optimizableVariable("Q1",[0 5]);
    Q2=optimizableVariable("Q2",[0 5]);
    Q3=optimizableVariable("Q3",[0 5]);
    Q4=optimizableVariable("Q4",[0 5]);
    vars=[Q1 Q2 Q3 Q4];
    estimator_cost=@(vars) wrapper_func(vars,simin);
    results=bayesopt(estimator_cost,vars,"MaxObjectiveEvaluations",num_solver_steps,...
        "AcquisitionFunctionName", "expected-improvement-plus",...
        "IsObjectiveDeterministic",true,"PlotFcn","all");
    
    set_param(simin.ModelName, FastRestart = "off");
    
    Q=diag(table2array(results.XAtMinObjective));
end

% Q = diag([1e-4 1e-4 20e-1 1e-1]);

function cost=wrapper_func(vars,simin)
    global burnout_time

    % QdB=[vars.Q1 vars.Q2 vars.Q3 vars.Q4];Q=diag(10.^(QdB/10));
    Q=diag([vars.Q1 vars.Q2 vars.Q3 vars.Q4]);
    R=diag([0.061410353 2.3659593e-05]);

    simin_step=simin;
    simin_step=simin_step.setVariable(kalm_process_cov=Q);
    simin_step=simin_step.setVariable(kalm_measure_cov=R);

    % rng(2);
    simout_step = sim(simin_step);
    logs = extractTimetable(simout_step.logsout);

    TR = timerange(seconds(burnout_time),seconds(100));
    logs_cut = logs(TR,:);

    cost=0;
    % cost=cost+rmse(logs_cut.position(:,2),logs_cut.altitude_est)*weights(1);

    % start_idx = find(seconds(logs.Time) > 3, 1, "first");
    % end_idx = length(logs.Time);

    % cost=cost+rmse(logs_cut.velocity(:,2),logs_cut.velocity_est)^2;
    % cost=cost+rmse(logs_cut.acceleration(:,2),logs_cut.accel_est);

    % cost=cost+(20*abs(1-mean(movstd(logs_cut.kalman_innov_norm,75))))^2;
    % cost=cost+(20*abs(1-mean(movstd(logs_cut.kalman_innov_norm(:,2),75))))^2;
    % cost = cost + max(abs(logs_cut.velocity(:,2)-logs_cut.velocity_est));

    % cost = cost + 0.5*(rmse(logs_cut.position(:,2), logs_cut.altitude_est)+2)^2;
    % cost = cost + 0.5*(rmse(logs_cut.velocity(:,2), logs_cut.velocity_est)+2)^2;
    % cost = cost + 0.5*(rmse(logs_cut.acceleration(:,2), logs_cut.accel_est)+2)^2;

    % cost = cost + (10*(abs(1-mean(movstd(logs_cut.kalman_innov_norm(:,1),75)))+2))^2;
    % cost = cost + (10*(abs(1-mean(movstd(logs_cut.kalman_innov_norm(:,2),150)))+2))^2;

    cost = cost + (10*(abs(1-mean(movstd(logs_cut.kalman_innov_norm(:,1),75)))+2))^2;
    cost = cost + (20*(abs(1-mean(movstd(logs_cut.kalman_innov_norm(:,2),150)))+2))^2;

    % cost1 = (10*(abs(1-mean(movstd(logs_cut.kalman_innov_norm(:,1),75)))+2))^2;
    % cost2 = (10*(abs(1-mean(movstd(logs_cut.kalman_innov_norm(:,2),400)))+2))^2; % 150
    % cost = sqrt(cost1^2 + cost2^2);

    % cost = cost + 3 .* sqrt(logs_cut.estimate_cov(end,1));
    % cost = cost + 3 .* sqrt(logs_cut.estimate_cov(end,2));
    % cost = cost + 3 .* sqrt(logs_cut.estimate_cov(end,3));

    % cost = cost + 20 .* mean(sqrt(logs_cut.estimate_cov(:,1)));
    % cost = cost + 20 .* mean(sqrt(logs_cut.estimate_cov(:,2)));
    % cost = cost + 20 .* mean(sqrt(logs_cut.estimate_cov(:,3)));
end

% close all;

% Q=diag([0.106286885925982 0.0413661452838036 19.3002373591853 0.217582165428583]);
% Q=diag([0.0776254796714698 0.586627467040288 16.7186495799650 0.537868506151282]);
% Q=diag(10.^(QdB/10));
% Q=diag([0.092021 1.96 3.7154 12.45]);

% Q = diag([1e-4 1e-4 20e-1 1e-1]);

% Q = diag([1e-4 1e-4 20e-2 1e-2]); % THIS ONE RIGHT HERE

% Q = diag([1e-4 1e-4 20e-2 1e-2]);

Q = diag([1e-4 1e-4 5e-2 0.4e-2]);

R=diag([0.061410353 2.3659593e-05]);

simin=simin.setVariable(kalm_process_cov=Q);
simin=simin.setVariable(kalm_measure_cov=R);

simout = sim(simin);
logs = extractTimetable(simout.logsout);

t_true=logs.Time;
alt_true=logs.position(:,2);
vel_true=logs.velocity(:,2);
accel_true=logs.acceleration(:,2);

alt_est=logs.altitude_est;
vel_est=logs.velocity_est;
accel_est=logs.accel_est;

figure(5);
tiledlayout(3,2,"TileIndexing","columnmajor","TileSpacing","compact","Padding","compact");

nexttile;
plot(t_true,alt_true);hold on;
plot(t_true,alt_est);
xline(time_to_burnout);
title("Altitude");

nexttile;
plot(t_true,vel_true);hold on;
plot(t_true,vel_est);
xline(time_to_burnout);
title("Velocity");

nexttile;
plot(t_true,accel_true,"DisplayName","True");hold on;
plot(t_true,accel_est,"DisplayName","Estimated");
plot(t_true,logs.accel_meas,"DisplayName","Measured");
xline(time_to_burnout,"DisplayName","Burnout");
title("Acceleration");
legend;

TR = timerange(seconds(burnout_time),seconds(100));
logs_cut = logs(TR,:);

nexttile;
alt_cov = 3 .* sqrt(logs.estimate_cov(:,1));
max_alt_error=max(abs(logs_cut.altitude_est-logs_cut.position(:,2)));
plot(t_true,alt_est-alt_true);hold on;grid on;
xline(time_to_burnout);
plot(t_true,[-1 1] .* alt_cov,"r--");
% yline([-5 5],"r--","LineWidth",1); % Good to have under
title("Alt Error | Max Post Burn: "+string(round(max_alt_error,2))+"m | Final Cov: "+string(round(alt_cov(end),2))+"m");

nexttile;
vel_cov = 3 .* sqrt(logs.estimate_cov(:,2));
max_vel_error=max(abs(logs_cut.velocity_est-logs_cut.velocity(:,2)));
plot(t_true,vel_est-vel_true);hold on;grid on;
xline(time_to_burnout);
plot(t_true,[-1 1] .* vel_cov,"r--");
% yline([-3 3],"r--","LineWidth",1);
title("Vel Error | Max Post Burn: "+string(round(max_vel_error,2))+"m/s | Final Cov: "+string(round(vel_cov(end),2))+"m/s");

nexttile;
accel_cov = 3 .* sqrt(logs.estimate_cov(:,3));
max_accel_error=max(abs(logs_cut.accel_est-logs_cut.acceleration(:,2)));
plot(t_true,accel_est-accel_true);hold on;grid on;
xline(time_to_burnout);
plot(t_true,[-1 1] .* accel_cov,"r--");
% yline([-3 3],"r--","LineWidth",1);
ylim([-5 5])
title("Accel Error | Max Post Burn: "+string(round(max_accel_error,2))+"m/s2 | Final Cov: "+string(round(accel_cov(end),2))+"m/s2");



figure(6);
tiledlayout(2,1,"TileIndexing","columnmajor","TileSpacing","compact","Padding","compact");

nexttile;
plot(t_true,logs.kalman_innov_norm(:,1));xline(burnout_time);
ylim([-4 4]);yline([-3 3],"r--","LineWidth",1);
title("Barometer Norm Innov | Std: "+string(round(mean(movstd(logs_cut.kalman_innov_norm(:,1),75)),2)));

nexttile;
plot(t_true,logs.kalman_innov_norm(:,2));xline(burnout_time);
ylim([-4 4]);yline([-3 3],"r--","LineWidth",1);
title("Accelerometer Norm Innov | Std: "+string(round(mean(movstd(logs_cut.kalman_innov_norm(:,2),400)),2)));