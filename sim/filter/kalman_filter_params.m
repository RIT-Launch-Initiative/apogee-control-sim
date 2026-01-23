function params = kalman_filter_params(mode)
    arguments
        mode (1,1) string;
    end
    
    params.input_rate = 100;
    params.output_rate = 10;
    dt = 1/params.input_rate;

    % we define 3 different filters using the same structure by setting
    % covariances to absurdly large or small values, as appropriate

    params.kalm_state = [1 dt dt^2/2 0; % z
        0 1 dt 0; % zdot
        0 0 1 0; % zddot
        0 0 0 1]; % abias
    params.kalm_output = [1 0 0 0;
        0 0 1 1];
    params.kalm_initial = [0; 0; 0; 9.8];


    switch mode
        case "accel-bias"
        % manually tuned
            params.kalm_process_cov = diagcov([0.05 0.1 5 0.01]); 
            params.kalm_meas_cov = [0.5044, -0.0144; 
                -0.0144, 0.0013]; 
        case "alt-accel"
            % small covariance for bias makes this behave like a filter that
            % just subtracts the initial guess for that bias (gravity) from the
            % measurement
            params.kalm_process_cov = diagcov([1e-4 1e-4 20 1e-50]);
            params.kalm_meas_cov = diagcov([0.23193856 0.0008]);
        case "alt"
            % large covariance for acceleration effectively gets rid of the accelerometer update
            params.kalm_process_cov = diagcov([1e-4 1e-4 20 1e-50]);
            params.kalm_meas_cov = diagcov([0.23193856 1e50]);
        case "ideal"
            params.kalm_process_cov = diagcov([1 1 1 1]);
            params.kalm_meas_cov = diagcov([1e-20 1e-20]);
        otherwise
            error("Unrecognized filter mode %s", mode)
    end
end

