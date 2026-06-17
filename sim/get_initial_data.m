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

    % In case events like burnout don't align perfectly with times
    events = simout.Properties.Events;
    eventdata = retime(simout,unique(events.Time),"linear");
    
    burnout_state = eventdata(eventfilter("BURNOUT"), :);

    params.t_0 = seconds(burnout_state.Time);
    params.position_init = burnout_state{1, ["Lateral distance", "Altitude"]}';
    params.velocity_init = burnout_state{1, ["Lateral velocity", "Vertical velocity"]}';
    % ^ these need to be transposed to columns to fit what Simulink expects
end
