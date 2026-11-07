function params = accel_params(mode)
    arguments 
        mode (1,1) string
    end
    params.ACCEL_RATE = 100;
    switch mode
        case "ideal"
            params.ACCEL_COV = 0;
            params.ACCEL_BIAS = 0;
            params.ACCEL_LSB = 1e-20;
            params.ACCEL_RANGE = Inf;
        case "lsm6dsl"
            params.ACCEL_COV = 8e-4;
            params.ACCEL_BIAS = 0;
            params.ACCEL_LSB = 488e-6 * 9.81;
            params.ACCEL_RANGE = 16 * 9.81;
        case "lsm6dsv"
            params.ACCEL_COV = 0.0361;
            params.ACCEL_BIAS = 0;
            params.ACCEL_LSB = 5e-4;
            params.ACCEL_RANGE = 16 * 9.81;
        case "lsm6dsv-45-deg"
            params.ACCEL_COV = 0.0361;
            params.ACCEL_BIAS = 0;
            params.ACCEL_LSB = 5e-4;
            params.ACCEL_RANGE = sqrt(2) * 16 * 9.81; % This is evil
        otherwise 
            error("Unrecognzied acceleromter %s", mode)
    end
end
