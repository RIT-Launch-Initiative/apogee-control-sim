function data = get_brake_data(mode)
    data = struct;
    data.PLATE_AREA = 2 * 9e-2 * 4e-2; % [m^2] Total area - N petal * Width * Height
    data.PLATE_CD = 1.2; % [-] Flat plate or so
    data.controller_rate = 10;
    data.observer_rate = 100;

    switch mode
        case "noisy"
            data.SERVO_TC = 0.1; % [s]
            data.SERVO_BL = 0.5e-3 / 4e-2; 
            % use "low power" mode - pressure x2 temperature x1
            data.BARO_QUANT = 1.32; % [Pa]
            data.BARO_RMSN = 2.5; % [Pa]

            filter_order = 2;
            pos_cutoff = 20;
            vel_cutoff = 5;
            [data.pos_num, data.pos_den] = butter(filter_order, 2*pos_cutoff/data.observer_rate);
            [data.vel_num, data.vel_den] = butter(filter_order, 2*vel_cutoff/data.observer_rate);
            data.N_pos = data.observer_rate / data.controller_rate;
            data.N_vel = data.observer_rate / data.controller_rate;
        case "ideal"
            data.SERVO_TC = 1e-6; % [s]
            data.SERVO_BL = 1e-6; % [-]
            data.BARO_QUANT = 1e-10; % [Pa] 
            data.BARO_RMSN = 0;

            data.pos_num = 1;
            data.pos_den = 1;
            data.vel_num = 1; 
            data.vel_den = 1;
            data.N_pos = 1;
            data.N_vel = 1;
    end
end
