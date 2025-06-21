function params = kalman_filter_params(mode)
    arguments
        mode (1,1) string;
    end
    
    params.input_rate = 100;
    params.output_rate = 10;
    dt = 1/params.input_rate;

    switch mode
        case "accel-bias"
            params.kalm_state = [1 dt dt^2/2 0; % z
                0 1 dt 0; % zdot
                0 0 1 0; % zddot
                0 0 0 1]; % abias
            % params.kalm_input = zeros(size(params.kalm_state, 1), 1);
            params.kalm_output = [1 0 0 0; 0 0 1 1];
            % params.kalm_ffwd = zeros(size(params.kalm_output, 1), 1);
            params.kalm_initial = [0; 0; 0; 9.8];
            params.kalm_meas_cov = diag([1, 8e-4]);
            params.kalm_process_cov = diag([0.001 0.001 1 0.01]);
        % case "alt"
        %     params.kalm_state = [1 dt dt^2/2 % z
        %         0 1 dt; % zdot
        %         0 0 1]; % zddot
        %     % params.kalm_input = zeros(size(params.kalm_state, 1), 1);
        %     params.kalm_output = [1 0 0];
        %     % params.kalm_ffwd = zeros(size(params.kalm_output, 1), 1);
        %     params.kalm_initial = [0; 0; 0];
        %     params.kalm_process_cov = diag([0 0 1]);  % XXX placeholder
        %     params.kalm_meas_cov = diag(1); % XXX placeholder
        otherwise
            error("Unrecognized filter mode %s", mode)
    end
end

