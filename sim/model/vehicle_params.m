% Get vehicle params in format expected by sim_2dof.slx
% [params] = ork2vehicle(doc)
% Inputs
%   mode            (string)    OpenRocket document
%   file_name       (string)    OpenRocket file name
%   sim_name        (string)    OpenRocket sim name
% Outputs
%   params    (struct)        
%       Structure with fields MASS_DRY, REF_AREA, DRAG_DATA, GROUND_LEVEL, GRAVITY

function [params] = vehicle_params(mode, file_name, sim_name)
    arguments
        mode (1,1) string;
        file_name (1,1) string;
        sim_name (1,1) string;
    end
    
    switch mode
        case "openrocket"
            % constants
            machs = [linspace(0, 1.5, 100)]';
            efforts = linspace(0, 1, 20); 
            plate_cd = 1.2;
            plate_num = 2;
            plate_width = sqrt(46.46)*1e-2; % [m]
            plate_length = plate_width; % [m]

            doc = openrocket(pfullfile("data", file_name));
            orksim = doc.sims(sim_name);

            % get dimensions etc.
            [~, params.MASS_DRY, ~] = doc.massdata("BURNOUT");
            [~, params.REF_AREA] = doc.refdims();

            % SimulationOptions don't include the gravity model, so we convert to
            % SimulationConditions to get that
            conds = orksim.getOptions().toSimulationConditions();
            site = conds.getLaunchSite();
            params.GROUND_LEVEL = site.getAltitude();
            params.GRAVITY = conds.getGravityModel().getGravity(site); % [m/s^2]
            
            % calculate approximate drag model
            % this can be simplified a lot by changing the model in Simulink
            % but this is more adaptable to the arbitrary drag table we will
            % end up using

            % calculate base rocket drag
            rocket_drag = NaN(size(machs)); 
            fc = doc.flight_condition(0, 0);
            for i_mach = 1:size(machs, 1)
                fc.setMach(machs(i_mach));
                [~, rocket_drag(i_mach), ~, ~, ~] = doc.aerodata3(fc);
            end

            assert(iscolumn(rocket_drag));
            assert(isrow(efforts));
            
            % airbrake contribution
            plate_drag = (plate_num * plate_cd * plate_width * plate_length) .* efforts;
            
            % total drag area (S*C_D) for all M by N points
            drag_values = plate_drag + params.REF_AREA .* rocket_drag;
            
            % convert to C_D dividing by S_R
            cd_values = drag_values ./ params.REF_AREA;
            % sure this is multiplied later by REF_AREA, but C_D is
            % conventionally normalized using a reference area

            % assign to output structure
            % provide both the Simulink LUT and the raw Xarray so that it can be modified if required
            params.plate_drag_area = plate_drag(end);
            params.cd_array = xarray(cd_values, mach = machs, effort = efforts);
            params.DRAG_LUT = xarray2lut(params.cd_array, ["mach", "effort"]);

            params.SERVO_TC = 0.1;
            params.SERVO_BL = 0.01;
        otherwise
            error("Unrecognized mode '%s'", mode)
    end
end

