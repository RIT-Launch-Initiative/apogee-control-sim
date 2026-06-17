project_globals;

data.name = launch_name;
data.date = string(datetime("now", "Format", "yyyy-MM-dd'T'HH:mm:ss"));

load(fullfile(launch_file,"cached","flight_info.mat"));
% data.lockout_ms = ceil(time_to_burnout*1000*1.05); % testbed
data.lockout_ms = ceil(seconds(time_to_mach)*1000*1.005); % risk
data.flight_time_ms = ceil((time_to_sim_end*1000)*1.5);

load(fullfile(launch_file,"orientation","orientation.mat"));
data.orientation_quat = orientation_quat;

dt = 1/100;
data.controller.state_transition_matrix = reshape([1 dt dt^2/2 0;...
                                                   0 1  dt     0;...
                                                   0 0  1      0;...
                                                   0 0  0      1]',1,[]);
controller_single;
kalman_K = permute(logs.kalman_K,[2 3 1]);kalman_K=kalman_K(:,:,end);
data.controller.kalman_gain = reshape(kalman_K',1,[]);
data.controller.kalman_output = reshape([1 0 0 0;0 0 1 1]',1,[]);
data.controller.initial_state = reshape([0; 0; 0; 9.81]',1,[]);

% data.atmosphere = flip(fitatmos(airdata));
data.atmosphere.pressure = airdata.PRES;
data.atmosphere.altitude = airdata.HGT;

load(fullfile(launch_file,"cached","bounddata.mat"));
data.quantile_lut.x = t_altitudes;
data.quantile_lut.lower_bounds = d_lowers;
data.quantile_lut.upper_bounds = d_uppers;

json_text = jsonencode(data,"PrettyPrint",true);
file = fopen(fullfile(launch_file,"cached",replace(data.date,":","-")+".json"),"wt");
fprintf(file,json_text);
fclose(file);