% clear;close all;
close;
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

num_solver_steps=80;

global alt_est alt_true
alt_est=[];alt_true=[];
global vel_est vel_true
vel_est=[];vel_true=[];
global accel_est accel_true
accel_est=[];accel_true=[];

%% Optimize

simin = simin.setVariable(kalm_process_cov = diag([1 1 1 1]));
simin = simin.setVariable(kalm_measure_cov = diag([0.23193856 0.0361]));
simin = simin.setModelParameter(SimulationMode = "accelerator", FastRestart = "on");

Q1=optimizableVariable("Q1",[0 20]);
Q2=optimizableVariable("Q2",[0 20]);
Q3=optimizableVariable("Q3",[0 20]);
Q4=optimizableVariable("Q4",[0 20]);
vars=[Q1 Q2 Q3 Q4];
estimator_cost=@(vars) wrapper_func(vars,simin);
results=bayesopt(estimator_cost,vars,"MaxObjectiveEvaluations",num_solver_steps,...
    "AcquisitionFunctionName", "expected-improvement-plus",...
    "IsObjectiveDeterministic",false,"PlotFcn","all");

set_param(simin.ModelName, FastRestart = "off");

function cost=wrapper_func(vars,simin)
    global burnout_time
    global alt_est alt_true
    global vel_est vel_true
    global accel_est accel_true

    % QdB=[vars.Q1 vars.Q2 vars.Q3 vars.Q4];Q=diag(10.^(QdB/10));
    Q=diag([vars.Q1 vars.Q2 vars.Q3 vars.Q4]);
    R=diag([0.23193856 0.0361]);

    simin_step=simin;
    simin_step=simin_step.setVariable(kalm_process_cov=Q);
    simin_step=simin_step.setVariable(kalm_measure_cov=R);

    % rng(2);
    simout_step = sim(simin_step);
    logs = extractTimetable(simout_step.logsout);

    % TR = timerange(duration(seconds(burnout_time)),duration(seconds(100)));
    % logs_cut = logs(TR,:);
    logs_cut = logs;

    % weights = [0.1 15 2 25 150]; somewhat ok for alt and vel
    weights = [1 1 1 1 1];

    cost=0;
    % cost=cost+rmse(logs_cut.position(:,2),logs_cut.altitude_est)*weights(1);
    cost=cost+rmse(logs_cut.velocity(:,2),logs_cut.velocity_est)^2*weights(2);
    cost=cost+rmse(logs_cut.acceleration(:,2),logs_cut.accel_est)*weights(3);
    % cost=cost+abs(1-std(logs_cut.kalman_innov_norm(:,1)))*weights(4);
    % cost=cost+abs(1-std(logs_cut.kalman_innov_norm(10:end,2)))*weights(5);
    % cost = cost + max(abs(logs_cut.velocity(:,2)-logs_cut.velocity_est));

    alt_est(end+1,:)=logs.altitude_est;
    alt_true(end+1,:)=logs.position(:,2);

    vel_est(end+1,:)=logs.velocity_est;
    vel_true(end+1,:)=logs.velocity(:,2);

    accel_est(end+1,:)=logs.accel_est;
    accel_true(end+1,:)=logs.acceleration(:,2);
end




%% Test

% close all;

Q=diag(table2array(results.XAtMinObjective));
% Q=diag(10.^(QdB/10));
% Q=diag([0.092021 1.96 3.7154 12.45]);
R=diag([0.23193856 0.0361]);

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
xline(time_to_burnout,"DisplayName","Burnout");
title("Acceleration");
legend;

TR = timerange(duration(seconds(burnout_time)),duration(seconds(100)));
logs_cut = logs(TR,:);

nexttile;
plot(t_true,alt_est-alt_true);hold on;grid on;
xline(time_to_burnout);
yline([-5 5],"r--","LineWidth",1); % Good to have under
title("Altitude Error");

nexttile;
max_vel_error=max(abs(logs_cut.velocity_est-logs_cut.velocity(:,2)));
plot(t_true,vel_est-vel_true);hold on;grid on;
xline(time_to_burnout);
yline([-3 3],"r--","LineWidth",1);
title("Vel Error | Max Post Burn: "+string(round(max_vel_error,2))+"m/s");

nexttile;
max_accel_error=max(abs(logs_cut.accel_est-logs_cut.acceleration(:,2)));
plot(t_true,accel_est-accel_true);hold on;grid on;
xline(time_to_burnout);
yline([-3 3],"r--","LineWidth",1);
ylim([-5 5])
title("Accel Error | Max Post Burn: "+string(round(max_accel_error,2))+"m/s2");



figure(6);
tiledlayout(2,1,"TileIndexing","columnmajor","TileSpacing","compact","Padding","compact");

nexttile;
plot(t_true,logs.kalman_innov_norm(:,1));xline(burnout_time);
ylim([-4 4]);yline([-3 3],"r--","LineWidth",1);
title("Barometer Norm Innov | Std: "+string(round(std(logs.kalman_innov_norm(:,1)),2)));

nexttile;
plot(t_true,logs.kalman_innov_norm(:,2));xline(burnout_time);
ylim([-4 4]);yline([-3 3],"r--","LineWidth",1);
title("Accelerometer Norm Innov | Std: "+string(round(std(logs.kalman_innov_norm(4:end,2)),2)));



%% Tuning convergence graphs

figure();
title("Tuning RMSE");

tiledlayout(3,1,"TileSpacing","compact","Padding","compact");

alt_rmse=[];
for i=1:num_solver_steps
    alt_rmse(end+1,1)=rmse(alt_true(i,:),alt_est(i,:));
end
alt_rmse=sort(alt_rmse,"descend");
% yyaxis left
% plot(alt_rmse); hold on
% ylabel("Maximum Alt. Error (m)");

vel_rmse=[];
for i=1:num_solver_steps
    vel_rmse(end+1,1)=rmse(vel_true(i,:),vel_est(i,:));
end
vel_rmse=sort(vel_rmse,"descend");
% yyaxis right
% plot(vel_rmse); hold on
% ylabel("Maximum Vel. Error (m/s)");

accel_rmse=[];
for i=1:num_solver_steps
    accel_rmse(end+1,1)=rmse(accel_true(i,:),accel_est(i,:));
end
accel_rmse=sort(accel_rmse,"descend");
% yyaxis right
% plot(vel_rmse); hold on
% ylabel("Maximum Vel. Error (m/s)");

nexttile;plot(alt_rmse);title("Altitude");
nexttile;plot(vel_rmse);title("Velocity");
nexttile;plot(accel_rmse);title("Acceleration");