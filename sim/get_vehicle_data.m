% Get vehicle data in format expected by sim_2dof.slx
% [data] = get_vehicle_data(doc)
% Inputs
%   doc     (openrocket)    document
% Outputs
%   data    (struct)        structure with fields MASS_DRY, etc. required by sim_2dof

function [data] = get_vehicle_data(doc)
    [~, data.MASS_DRY, inertia] = doc.massdata("BURNOUT");
    data.PITCH_INERTIA = inertia(2);
    [~, data.REF_AREA] = doc.refdims();

    % drag lookup table using aerodata3()
    n_drag_points = 100;
    dragtable = table(linspace(0, 1.5, n_drag_points)', NaN(n_drag_points,1), ...
        VariableNames = ["MACH", "DRAG"]);
    fc = doc.flight_condition(0);
    for i_mach = 1:height(dragtable)
        fc.setMach(dragtable{i_mach, "MACH"});
            [~, dragtable{i_mach, "DRAG"}, ~, ~, ~] = doc.aerodata3(fc);
    end
    data.DRAG_DATA = dragtable;

    orsim = doc.sims(1);
    % SimulationOptions don't include the gravity model, so we convert to
    % SimulationConditions to get that
    conds = orsim.getOptions().toSimulationConditions();
    site = conds.getLaunchSite();
    data.GROUND_LEVEL = site.getAltitude();
    data.GRAVITY = conds.getGravityModel().getGravity(site); % [m/s^2]
end

