function params = baro_params(mode)
    arguments 
        mode (1,1) string
    end
    params.BARO_RATE = 100;
    switch mode
        case "ideal"
            params.BARO_COV = 0;
            params.BARO_LSB = 1e-20;
        case "bmp388"
            noise_rms = 4.3; % [Pa]
            params.BARO_COV = noise_rms^2;
            params.BARO_LSB = 1.32; % [Pa];
        case "ctrl"
            noise_rms = 7; % [Pa]
            params.BARO_COV = noise_rms^2;
            params.BARO_LSB = 1.32; % [Pa];
        case "controls_module"
            noise_rms = 3.03514883018844; % [Pa]
            params.BARO_COV = noise_rms^2; % From emma's L1
            params.BARO_LSB = 1.0; % [Pa]
        case "super_freak"
            fprintf("deleting system32");
        otherwise 
            error("Unrecognzied barometer %s", mode);
    end
end
