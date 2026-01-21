clear;
project_globals;

alt_p = baro_params("bmp388");
alt_p.GROUND_LEVEL = orkopts.getLaunchAltitude();

accel_p = accel_params("lsm6dsl");
accel_p.GRAVITY = 9.81;
kalm_p = kalman_filter_params("accel-bias");

% orkopts.setLaunchRodAngle(deg2rad(20));
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

[process, measure] = tune_cov(simin, orkdata, [0 NaN NaN NaN], [18.49 * 0.112^2 8e-4]);
% [process, measure] = tune_cov(simin, orkdata, [1e-6 1e-3 10 1], [0.77 0.1].^2);
% [process, measure] = tune_cov(simin, orkdata, [0 0 NaN 1e-50], [NaN 1e50]);
% [process, measure] = tune_cov(simin, orkdata, [1e-6 1e-3 NaN NaN], [NaN NaN]);

fprintf("Tuned process covariance: %s \n", mat2str(process));
fprintf("Tuned measurement covariance: %s \n", mat2str(measure));

simin = simin.setVariable(kalm_process_cov = diagcov(process));
simin = simin.setVariable(kalm_measure_cov = diagcov(measure));

simout = sim(simin);
logs = extractTimetable(simout.logsout);
logs = fillmissing(logs, "previous");
compare_data = synchronize(logs, orkdata, "regular", "linear", SampleRate = kalm_p.output_rate);

% compare_interval = timerange(seconds(3), seconds(15));
% compare_data = compare_data(compare_interval, :);

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
    init_val = ones(1, n_inputs);
    [init_pcov, init_mcov] = assignval(init_val);

    simin = simin.setVariable(kalm_process_cov = diagcov(init_pcov));
    simin = simin.setVariable(kalm_measure_cov = diagcov(init_mcov));
    simin = simin.setModelParameter(SimulationMode = "accelerator", FastRestart = "on");

    simout = sim(simin);
    compare_data = retime(orkdata, seconds(simout.tout), "linear");

    opts = optimset(Display = "iter", TolX = 1e-6, TolFun = 1e-6, ...
        PlotFcns = {@optimplotx}, MaxIter = 500);
    % test_signal = "accel_est";
    % ref_signal = "Vertical acceleration";

    opt_val = fminsearch(@estimator_cost, init_val, opts);
    [process, measure] = assignval(opt_val);

    set_param(simin.ModelName, FastRestart = "off");

    function cost = estimator_cost(val)
        [pcov, mcov] = assignval(val);
        simin_step = simin;
        simin_step = simin_step.setVariable(kalm_process_cov = diagcov(pcov));
        simin_step = simin_step.setVariable(kalm_measure_cov = diagcov(mcov));

        compare_interval = timerange(seconds(3), seconds(15));
        % compare_interval = timerange(seconds(-Inf), seconds(Inf));
        weights = [0 1 0];
        % weights = [1 1 1];

        % rng(2);
        simout_step = sim(simin_step);
        logs = extractTimetable(simout_step.logsout);
        errs = logs{compare_interval, ["altitude", "velocity", "accel"] + "_est"} - ...
            compare_data{compare_interval, ["Altitude", "Vertical velocity", "Vertical acceleration"]};
        costs = mean(errs, 1).^2 + var(errs, 0, 1);
        cost = dot(costs, weights);
        % cost = sum(abs(mean(errs, )), 2)
        % errs = abs(mean(err))
        % err = simout_step.logsout.get(test_signal).Values.Data - compare_data.(ref_signal);
        % cost = abs(mean(err)) + std(err);
    end

    function [pcov, mcov] = assignval(val)
        val = 10 .^ (val/20);
        % val = val.^2 + 1e-20;

        pcov = diag_process;
        mcov = diag_measure;
        pcov(i_pcov) = val(1:sum(i_pcov));
        mcov(i_mcov) = val((sum(i_pcov) + 1):(sum(i_pcov) + sum(i_mcov)));
    end
end
