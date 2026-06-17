sim_name = "15mph-Midland";
[~,~,P,~,~,~] = atmosisa(3048);
apogee_target = interp1(airdata.PRES,airdata.HGT,P); % [m]
% apogee_target = 3048 + 180; % [m]