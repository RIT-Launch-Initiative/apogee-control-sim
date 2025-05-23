function params = alt_filter_params(mode)
    arguments 
        mode (1,1) string
    end

    params.input_rate = 100;
    params.output_rate = 10;

    switch mode
        case "none"
            params.pos_num = 1;
            params.pos_den = 1;
            params.vel_num = 1; 
            params.vel_den = 1;
            params.vel_avg = 1;

        case "designed"
            pos_cutoff = 20;
            pos_order = 2;
            vel_cutoff = 5;
            vel_order = 2;

            [params.pos_num, params.pos_den] = butter(pos_order, 2*pos_cutoff/params.input_rate);
            [params.vel_num, params.vel_den] = butter(vel_order, 2*vel_cutoff/params.input_rate);
            params.vel_avg = params.input_rate / params.output_rate;
        otherwise 
            error("Unrecognized alititude filter mode %s", mode);
    end
end

