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
            servo_angle_range = 152.569 - 9.169; % [deg]
            servo_time_per_angle = 0.110 / 60; % [s/deg]
            servo_open_time = servo_angle_range * servo_time_per_angle; % [s]
            settling_time_to_TC = 3; % for 95% settled
            params.SERVO_TC = servo_open_time / settling_time_to_TC; % [s]
        otherwise
            error("Unrecognzied actuator mode %s", mode)
    end
end

