function params = kalman_filter_params(mode,launch_file)
    arguments
        mode (1,1) string;
        launch_file (1,1) string;
    end
    
    params.input_rate = 100;
    params.output_rate = 100; %10 RATE
    dt = 1/params.input_rate;

    % we define 3 different filters using the same structure by setting
    % covariances to absurdly large or small values, as appropriate

    params.kalm_state = [1 dt dt^2/2 0; % z
        0 1 dt 0; % zdot
        0 0 1 0; % zddot
        0 0 0 1]; % abias
    params.kalm_output = [1 0 0 0;
                          0 0 1 1];
    % params.kalm_output = [1 -0.05 -(1/2)*0.05 0;
    %     0 0 1 1];
    params.kalm_initial = [0; 0; 0; 9.81];


    switch mode
        case "alt-accel-bias"
            % load(fullfile(launch_file,"tune","tune.mat"));
            % params.kalm_process_cov = diag(variances);

            % params.kalm_process_cov = diag([1e-4 1e-4 20e-1 1e-1]); % diag([1e-4 1e-4 1e-4 1e-30]); % 1
            % params.kalm_process_cov = diag([1e-4 1e-4 5e-1 1e-1]); % What I was testing with before 6.13.26 what flew

            % i_pos = 1; i_vel = 2; i_acc = 3; i_bia = 4;
            % params.kalm_process_cov = zeros(4);
            % params.kalm_process_cov(i_pos,i_pos) = 1e-4;
            % params.kalm_process_cov(i_vel,i_vel) = 1e-4;
            % params.kalm_process_cov(i_acc,i_acc) = 0.05;
            % params.kalm_process_cov(i_bia,i_bia) = 0.004; % desired testbed 2, backup for risk
            % 
            % params.kalm_process_cov = params.kalm_process_cov' + triu(params.kalm_process_cov,1);

            params.kalm_process_cov = diag([1e-4 1e-4 0.05 0.004]);

            params.kalm_meas_cov = diag([0.051790450 (0.00813558389199730)^2]);

            % params.kalm_process_cov = diag([97.0835435625974 72.5451419260469 21.2652387325629 0.235904485903042]);

            % params.kalm_process_cov = diag([99.7958 69.0780 65.0112 33.5632]);

            % params.kalm_process_cov = diag([1.0E-4 1.0E-4 0.05 0.004]); % Testbed 2

            % params.kalm_process_cov(i_acc, i_bia) = 1;
            % params.kalm_meas_cov = diag([1e6 1e-5]);

            % params.kalm_process_cov = diag([0.0776254796714698 0.586627467040288 16.7186495799650 0.537868506151282]);
            % params.kalm_meas_cov = diag([0.23193856 0.0361]); % From Yev for OMEN

            % params.kalm_meas_cov = diag([0.061410353 2.3659593e-05]); % From emma's L1 using get_emma_rocket_noise.m

            % Manually tuned by Yev for OMEN
            % params.kalm_process_cov = diag([1e-4 1e-4 20 1]); 
            % params.kalm_meas_cov = diag([0.23193856 0.0008]);
        case "alt-accel"
            % small covariance for bias makes this behave like a filter that
            % just subtracts the initial guess for that bias (gravity) from the
            % measurement
            params.kalm_process_cov = diag([1e-4 1e-4 20 1e-50]);
            params.kalm_meas_cov = diag([0.23193856 0.0008]);
        case "alt"
            % large covariance for acceleration effectively gets rid of the accelerometer update
            params.kalm_process_cov = diag([1e-4 1e-4 20 1e-50]);
            params.kalm_meas_cov = diag([0.23193856 1e50]);
        otherwise
            error("Unrecognized filter mode %s", mode)
    end
end

