clear;
project_globals;

alt_p = baro_params("ctrl");
accel_p = accel_params("ctrl");
accel_p.GRAVITY = 9.81;
kalm_p = kalman_filter_params("accel-bias");


kalm_p.kalm_meas_cov = diag([0.1, 8e-4]);
kalm_p.kalm_process_cov = diag([0.001 0.001 1 1e-2]);

% kalm_p.kalm_meas_cov = diag([0.1, 8e-4]);
% kalm_p.kalm_process_cov = diag([0.001 0.001 1 1e-10]);

% kalm_p.kalm_meas_cov = diag([0.1, 1e10]);
% kalm_p.kalm_process_cov = diag([0.001 0.001 1 1e-10]);


% kalm_p.kalm_meas_cov = diag([5, 8e-4]);
% kalm_p.kalm_process_cov = diag([0.01 0.01 20 1e-10]);

orksim = doc.sims("MATLAB");
simopts = orksim.getOptions();

alt_p.GROUND_LEVEL = simopts.getLaunchAltitude();

orkdata = doc.simulate(orksim, outputs = "ALL", stop = "APOGEE");
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

% [process, measure] = tune_cov(simin, orkdata, [0.0001 0.0001 NaN 1e-20], [18.49 * 0.112^2 8e-4]);
% [process, measure] = tune_cov(simin, orkdata, [1e-6 1e-6 NaN 1e-20], [0.77 0.192].^2);
[process, measure] = tune_cov(simin, orkdata, [1e-6 1e-6 NaN 1e-20], [0.77 1e20].^2);

fprintf("Tuned process covariance: %s \n", mat2str(process));
fprintf("Tuned measurement covariance: %s \n", mat2str(measure));

simin = simin.setVariable(kalm_process_cov = diag(process));
simin = simin.setVariable(kalm_measure_cov = diag(measure));

simout = sim(simin);
logs = extractTimetable(simout.logsout);
logs = fillmissing(logs, "previous");
compare_data = synchronize(orkdata, logs, "regular", "linear", SampleRate = kalm_p.output_rate);

compare_data.alt_err = compare_data.altitude_est - compare_data.altitude_meas;
compare_data.vel_err = compare_data.velocity_est - compare_data.("Vertical velocity");
compare_data.accel_err = compare_data.accel_est - compare_data.("Vertical acceleration");
true_args = {"DisplayName", "True"};
meas_args = {"DisplayName", "Measured"};
est_args = {"DisplayName", "Estimated"};

figure;
layout = tiledlayout(3,2);
layout.TileIndexing = "rowmajor";

nexttile; hold on; grid on;
plot(orkdata.Time, orkdata.Altitude, true_args{:});
plot(logs.Time, logs.altitude_meas, meas_args{:});
plot(logs.Time, logs.altitude_est, est_args{:});

nexttile; hold on; grid on;
plot(compare_data.Time, compare_data.alt_err);
fprintf("Position: mean %.2f m | std %.2f m\n", ...
    mean(compare_data.alt_err), std(compare_data.alt_err));

nexttile; hold on; grid on;
plot(orkdata.Time, orkdata.("Vertical velocity"), true_args{:})
plot(logs.Time, logs.velocity_meas, meas_args{:});
plot(logs.Time, logs.velocity_est, est_args{:});

nexttile; hold on; grid on;
plot(compare_data.Time, compare_data.vel_err);
fprintf("Velocity: mean %.2f m/s | std %.2f m/s\n", ...
    mean(compare_data.vel_err), std(compare_data.vel_err));

nexttile; hold on; grid on;
plot(orkdata.Time, orkdata.("Vertical acceleration"), true_args{:})
plot(logs.Time, logs.accel_meas, meas_args{:});
plot(logs.Time, logs.accel_est, est_args{:});
plot(logs.Time, logs.accel_bias_est, "--", DisplayName = "Bias");

nexttile; hold on; grid on;
plot(compare_data.Time, compare_data.accel_err);
fprintf("Acceleration: mean %.2f m/s^2 | std %.2f m/s^2\n", ...
    mean(compare_data.accel_err), std(compare_data.accel_err));

function [process, measure] = tune_cov(simin, orkdata, diag_process, diag_measure)
    arguments
        simin (1,1) Simulink.SimulationInput;
        orkdata timetable;
        diag_process (1,4) double;
        diag_measure (1,2) double;
    end
    
    i_pcov = isnan(diag_process);
    i_mcov = isnan(diag_measure);
    n_inputs = sum(i_pcov) + sum(i_mcov);
    init_val = 1 * ones(1, n_inputs);
    [init_pcov, init_mcov] = assignval(init_val);
    simin = simin.setVariable(kalm_process_cov = diag(init_pcov));
    simin = simin.setVariable(kalm_measure_cov = diag(init_mcov));

    simout = sim(simin);
    compare_data = retime(orkdata, seconds(simout.tout), "linear");

    opts = optimset(Display = "iter", TolX = 1e-5, TolFun = 1e-5, ...
        PlotFcns = {@optimplotx});
    opt_val = fminsearch(@estimator_cost, init_val, opts);
    [process, measure] = assignval(opt_val);

    function cost = estimator_cost(val)
        [pcov, mcov] = assignval(val);
        simin_step = simin;
        simin_step = simin_step.setVariable(kalm_process_cov = diag(pcov));
        simin_step = simin_step.setVariable(kalm_measure_cov = diag(mcov));

        rng(0);
        simout_step = sim(simin_step, UseFastRestart = "on");
        vel_compare = simout_step.logsout.get("velocity_est").Values.Data;
        err = vel_compare - compare_data.("Vertical velocity");
        cost = abs(mean(err)) + std(err);
    end

    function [pcov, mcov] = assignval(val)
        val = abs(val) + 1e-20;
        pcov = diag_process;
        mcov = diag_measure;
        pcov(i_pcov) = val(1:sum(i_pcov));
        mcov(i_mcov) = val((sum(i_pcov) + 1):(sum(i_pcov) + sum(i_mcov)));
    end
end
