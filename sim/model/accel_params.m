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
            params.ACCEL_RANGE = 32 * 9.81;
        otherwise 
            error("Unrecognzied acceleromter %s", mode)
    end
end
