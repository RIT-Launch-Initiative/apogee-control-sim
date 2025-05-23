function params = actuator_params(mode)
    arguments 
        mode (1,1) string;
    end

    switch mode
        case "ideal"
            params.SERVO_BL = 1e-10;
            params.SERVO_TC = 0.01/4;
        case "laggy"
            params.SERVO_BL = 0.5e-3 / 4e-2; % 0.5mm to fraction
            params.SERVO_TC = 0.1; % [s]
        otherwise
            error("Unrecognzied actuator mode %s", mode)
    end
end

