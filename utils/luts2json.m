function luts2json(name,orientation_quat,state_transition_matrix,kalman_gain,initial_state,kalman_output,uppers,lowers,airdata,flight_time,write_path)
    arguments
        name string
        orientation_quat (1,4) double
        state_transition_matrix (4,4) double
        kalman_gain (4,2) double
        initial_state (4,1) double
        kalman_output (2,4) double
        % uppers xarray
        % lowers xarray
        uppers double
        lowers double
        airdata table
        flight_time double
        write_path string = ""
    end

    data.name = name;
    data.date = string(datetime("now", "Format", "yyyy-MM-dd'T'HH:mm:ss"));
    data.orientation_quat = orientation_quat;
    data.controller.state_transition_matrix = state_transition_matrix;
    data.controller.kalman_gain = kalman_gain;
    data.controller.initial_state = initial_state;
    data.controller.kalman_output = kalman_output;
    % data.quantile_lut.x = uppers.("alt");
    % data.quantile_lut.lower_bounds = double(lowers);
    % data.quantile_lut.upper_bounds = double(uppers);
    data.quantile_lut.x = 1;
    data.quantile_lut.lower_bounds = 1;
    data.quantile_lut.upper_bounds = 1;
    data.atmos = flip(fitatmos(airdata));
    data.flight_time = flight_time;

    json_text = jsonencode(data,"PrettyPrint",true);
    file = fopen(fullfile(write_path,data.name+".txt"),"wt");
    fprintf(file,json_text);
    fclose(file);
end
