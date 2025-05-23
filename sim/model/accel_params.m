function params = accel_params(mode)
    arguments 
        mode (1,1) string
    end
    params.ACCEL_RATE = 100;
    switch mode
        case "ideal"
            params.ACCEL_PNOISE = 0;
            params.ACCEL_BIAS = 0;
            params.ACCEL_LSB = 1e-20;
        case "lsm6dsl"
            % XXX these are wrong
            params.ACCEL_PNOISE = 0;
            params.ACCEL_BIAS = 0;
            params.ACCEL_LSB = 1e-20;
        otherwise 
            error("Unrecognzied acceleromter %s", mode)
    end
end
