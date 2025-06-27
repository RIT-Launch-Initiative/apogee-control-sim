function params = baro_params(mode)
    arguments 
        mode (1,1) string
    end
    params.BARO_RATE = 100;
    switch mode
        case "ideal"
            params.BARO_COV = 0;
            params.BARO_LSB = 1e-20;
            params.PRES_TC = 0.001;
        case "bmp388"
            noise_rms = 4.3; % [Pa]
            params.BARO_COV = noise_rms^2;
            params.BARO_LSB = 1.32; % [Pa];
            params.PRES_TC = 0.1;
        case "ctrl"
            noise_rms = 7; % [Pa]
            params.BARO_COV = noise_rms^2;
            params.BARO_LSB = 1.32; % [Pa];
            params.PRES_TC = 0.1;
        otherwise 
            error("Unrecognzied barometer %s", mode);
    end
end
