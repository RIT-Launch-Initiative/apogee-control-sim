clear;close all;
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

simin = simin.setVariable(kalm_process_cov = diag([10 10 10 1]));
simin = simin.setVariable(kalm_measure_cov = diag([0.23193856 0.0008]));
simin = simin.setModelParameter(SimulationMode = "accelerator", FastRestart = "on");

num_solver_steps=120;

global alt_est alt_meas
alt_est=[];alt_meas=[];
global alt_v accel_v
alt_v=[];accel_v=[];
global alt_xcorr
alt_xcorr=[];
global vel_est vel_meas
vel_est=[];vel_meas=[];

Q1=optimizableVariable("Q1",[0 30]);
Q2=optimizableVariable("Q2",[0 30]);
Q3=optimizableVariable("Q3",[0 30]);
vars=[Q1 Q2 Q3];
estimator_cost=@(vars) wrapper_func(vars,simin);
results=bayesopt(estimator_cost,vars,"MaxObjectiveEvaluations",num_solver_steps,...
    "AcquisitionFunctionName", "expected-improvement-plus",...
    "IsObjectiveDeterministic",false,"PlotFcn","all");

figure();
title("Tuning RMSE");
alt_rmse=[];
for i=1:num_solver_steps
    alt_rmse(end+1,1)=rmse(alt_est(i,:),alt_meas(i,:));
end
alt_rmse=sort(alt_rmse,"descend");
yyaxis left
plot(alt_rmse); hold on
ylabel("Maximum Alt. Error (m)");

vel_rmse=[];
for i=1:num_solver_steps
    vel_rmse(end+1,1)=rmse(vel_est(i,:),vel_meas(i,:));
end
vel_rmse=sort(vel_rmse,"descend");
yyaxis right
plot(vel_rmse); hold on
ylabel("Maximum Vel. Error (m/s)");




% figure();
% title("Special Things");
% alt_v_std=[];
% for i=1:num_solver_steps
%     alt_v_std(end+1,1)=abs(1-std(alt_v(i,:)));
% end
% alt_v_std=sort(alt_v_std,"descend");
% yyaxis left
% plot(alt_v_std+1,"LineWidth",1);
% ylabel("Normalized Alt. Innovation σ (-)");
% xlabel("Solver Iteration (-)");
% yyaxis right
% plot(sort(alt_xcorr,"descend"));
% ylabel("Alt. Autocorrelation Sum (-)");



% data = results.XTrace;
% y = results.ObjectiveTrace;y=y.^2;y=y./max(y);
% figure;
% scatter3(data.Q1, data.Q2, data.Q3, 50, y, "filled");colorbar;
% xlabel("X1"); ylabel("X2"); zlabel("X3");
% title("Points Evaluated by BayesOpt (Color = Objective Value)");
% grid on;colormap(parula);

set_param(simin.ModelName, FastRestart = "off");

function cost=wrapper_func(vars,simin)
    global alt_est alt_meas
    global alt_v accel_v
    global alt_xcorr
    global vel_est vel_meas

    Q=diag([vars.Q1 vars.Q2 vars.Q3 1]);
    R=diag([0.23193856 0.0008]);

    simin_step=simin;
    simin_step=simin_step.setVariable(kalm_process_cov=Q);
    simin_step=simin_step.setVariable(kalm_measure_cov=R);

    % rng(2);
    simout_step = sim(simin_step);
    logs = extractTimetable(simout_step.logsout);
    % [r,lags]=xcorr(logs.v_innovation(:,1),"normalized");
    % out=trapz(lags,r);
    % [r,lags]=xcorr(logs.v_innovation(:,2),"normalized");
    % out=out+trapz(lags,r);logs.acceleration(:,2)

    cost=rmse(logs.altitude_meas,logs.altitude_est)^2;
    cost=cost+rmse(logs.velocity_meas,logs.velocity_est)^2;
    cost=cost+rmse(logs.accel_meas,logs.accel_est)^2;
    % [r,lags]=xcorr(logs.v_innovation(:,1),"normalized");
    % cost=cost+trapz(lags,r)*2;
    % [r,lags]=xcorr(logs.v_innovation(:,2),"normalized");
    % cost=cost+trapz(lags,r)*2;
    % % % cost=cost+abs(1-std(logs.innovation_norm(:,1)))^4;
    % % % cost=cost+abs(1-std(logs.innovation_norm(:,2)))^4;
    % cost=cost+xcorr(logs.v_innovation(:,1),"normalized");

    % % % [r,lags]=xcorr(logs.v_innovation(:,1),"normalized");
    % % % r=r(lags>=0);lags=lags(lags>=0);
    % cost=cost+trapz(lags,abs(r))/100;

    alt_est(end+1,:)=logs.altitude_est;
    alt_meas(end+1,:)=logs.altitude_meas;

    % % % alt_v(end+1,:)=logs.v_innovation(:,1);
    % % % accel_v(end+1,:)=logs.v_innovation(:,2);

    % alt_xcorr(end+1,:)=trapz(lags,abs(r));
    % % % alt_xcorr(end+1,:)=trapz(r(~(r<1.96/sqrt(length(logs.Time)) & r>-1.96/sqrt(length(logs.Time)))));

    vel_est(end+1,:)=logs.velocity_est;
    vel_meas(end+1,:)=logs.velocity_meas;
end
