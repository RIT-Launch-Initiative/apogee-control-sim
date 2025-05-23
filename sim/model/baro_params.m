function params = baro_params(mode)
    arguments 
        mode (1,1) string
    end
    params.BARO_RATE = 100;
    switch mode
        case "ideal"
            params.BARO_PNOISE = 0;
            params.BARO_LSB = 1e-20;
        case "bmp388"
            noise_rms = 2.5; % [Pa]
            params.BARO_PNOISE = noise_rms^2/params.BARO_RATE;
            params.BARO_LSB = 1.32; % [Pa];
        otherwise 
            error("Unrecognzied barometer %s", mode);
    end
end
