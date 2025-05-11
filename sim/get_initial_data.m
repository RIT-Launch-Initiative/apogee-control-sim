% Get initial conditions from OpenRocket simulation output
% simout = get_initial_data(simout)
% Inputs
%   simout      (timetable)     Output of openrocket.simulate(...);
% Outputs
%   params      (struct)        Struct with fields t_0, t_f, position_init, velocity_init
function params = get_initial_data(simout)
    arguments
        simout timetable
    end
    
    coastrange = timerange(eventfilter("BURNOUT"), eventfilter("APOGEE"), "closed");
    coast = simout(coastrange, :);
    burnout_state = simout(eventfilter("BURNOUT"), :);

    params.t_0 = seconds(coast.Time(1));
    params.t_f = seconds(coast.Time(end)) + 2;
    params.position_init = coast{1, ["Lateral distance", "Altitude"]}';
    params.velocity_init = coast{1, ["Lateral velocity", "Vertical velocity"]}';
    % ^ these need to be transposed to columns to fit what Simulink expects
end
