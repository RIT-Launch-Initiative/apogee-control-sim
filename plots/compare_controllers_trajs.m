clear;
project_globals;

orkdata = doc.simulate(doc.sims(sim_name), outputs = "ALL", stop = "APOGEE");
inits = get_initial_data(orkdata);

lower_bounds = luts.lower_bounds;
upper_bounds = luts.upper_bounds;

const_sim_path = pfullfile("sim", "sim_const");
% altitudes = linspace(alt_start, apogee_target, 100);
init_altitude = 1002;
% velocities = 250;
% velocities = 243;
desired_effort = 0.82;
init_velocity = interp1(lower_bounds.alt, (upper_bounds.data - lower_bounds.data) * desired_effort, init_altitude) + interp1(lower_bounds.alt, lower_bounds.data, init_altitude);

init_params.t_0 = time_start;
init_params.position_init = [0 init_altitude];
init_params.velocity_init = [0 init_velocity];

const_simin = structs2inputs(const_sim_path, vehicle_params("openrocket", rocket_file, sim_name));
const_simin = structs2inputs(const_simin, init_params);
const_simin = structs2inputs(const_simin, struct(brake_on = 0, brake_off = 100));

% Zero effort sim
zero_simin = structs2inputs(const_simin, struct(const_brake = 0, brake_on = 0, brake_off = 100));
zero_simout = sim(zero_simin);
zero_logs = zero_simout.logsout.extractTimetable;

% Full effort sim
full_simin = structs2inputs(const_simin, struct(const_brake = 1, brake_on = 0, brake_off = 100));
full_simout = sim(full_simin);
full_logs = full_simout.logsout.extractTimetable;

% Constant effort sim
turn_airbrakes_off = false;
target_const_effort = 0.5;
Kp = 0;

simin = Simulink.SimulationInput("sim_controller");

simin = structs2inputs(simin, accel_params("ideal"));
simin = structs2inputs(simin, baro_params("ideal"));
simin = simin.setVariable(filter_mode = "through");

lookups = matfile(luts_file, Writable = false);

simin = simin.setVariable(controller_rate = 100);
simin = simin.setVariable(control_mode = "maxm");
simin = simin.setVariable(lower_bound_lut = ...
    xarray2lut(lookups.lower_bounds, "alt"));
simin = simin.setVariable(upper_bound_lut = ...
    xarray2lut(lookups.upper_bounds, "alt"));

simin = simin.setVariable(target_const_effort = target_const_effort);
simin = simin.setVariable(Kp = Kp);

simin = structs2inputs(simin, vehicle_params("openrocket", rocket_file, sim_name));
simin = structs2inputs(simin, init_params);
simin = simin.setVariable(dt = 0.01);

% For starting simulation on ground
orkdata_for_simulink = orkdata(:,[]);
orkdata_for_simulink.position = [orkdata.("Lateral distance") orkdata.Altitude];
orkdata_for_simulink.velocity = [orkdata.("Lateral velocity") orkdata.("Vertical velocity")];
orkdata_for_simulink.acceleration = [orkdata.("Lateral acceleration") orkdata.("Vertical acceleration")];
orkdata_for_simulink.pitch = orkdata.("Vertical orientation (zenith)");
orkdata_for_simulink(seconds(0), :) = orkdata_for_simulink(1,:); % zero out OR weirdness at time zero
orkdata_for_simulink = sortrows(orkdata_for_simulink);
orkdata_for_simulink(1:2, :).position = [0 0; 0 0];
orkdata_for_simulink(1:2, :).velocity = [0 0; 0 0];
orkdata_for_simulink(1:2, :).acceleration = [0 0; 0 0];
simin = simin.setVariable(orkdata_for_simulink = orkdata_for_simulink);

const_simout = sim(simin);
const_logs = extractTimetable(const_simout.logsout);
const_logs = fillmissing(const_logs, "previous");

% Max margin effort sim
turn_airbrakes_off = false;
target_const_effort = 0.5;
Kp = 10;

simin = simin.setVariable(target_const_effort = target_const_effort);
simin = simin.setVariable(Kp = Kp);

max_simout = sim(simin);
max_logs = extractTimetable(max_simout.logsout);
max_logs = fillmissing(max_logs, "previous");





figure(Name="This state's trajectory");
tiledlayout(2,1, TileSpacing="compact", Padding="compact");

nexttile; hold on; grid on;
plot(zero_logs.Time, zero_logs.position(:,2));
plot(full_logs.Time, full_logs.position(:,2));
plot(const_logs.Time, const_logs.position(:,2));
plot(max_logs.Time, max_logs.position(:,2));

nexttile; hold on; grid on;
plot(max_logs.Time, interp1(lower_bounds.alt, lower_bounds.data, max_logs.position(:,2)), "--k", DisplayName="Lower target bound");
plot(max_logs.Time, interp1(upper_bounds.alt, upper_bounds.data, max_logs.position(:,2)), "--k", DisplayName="Upper target bound");
plot(zero_logs.Time, zero_logs.velocity(:,2), DisplayName="This state's upper bound");
plot(full_logs.Time, full_logs.velocity(:,2), DisplayName="This state's lower bound");
plot(const_logs.Time, const_logs.velocity(:,2), DisplayName="Const. effort control");
plot(max_logs.Time, max_logs.velocity(:,2), DisplayName="Max margin control");

legend;



figure(Name="Bounds of this specifi state");
tiledlayout(3,1, TileSpacing="compact", Padding="compact");

nexttile([2 1]); hold on; grid on;
min_lower = min(zero_logs.position(:,2)) + 1;
max_lower = max(upper_bounds.alt) - 1;
fill([min_lower:max_lower max_lower:-1:min_lower], [min(interp1(zero_logs.position(1:end-1,2),zero_logs.velocity(1:end-1,2),min_lower:max_lower),interp1(upper_bounds.alt, upper_bounds.data,min_lower:max_lower)) max(interp1(full_logs.position(1:end-1,2),full_logs.velocity(1:end-1,2),max_lower:-1:min_lower),interp1(lower_bounds.alt, lower_bounds.data,max_lower:-1:min_lower))], [0.1 0.8 0.1], FaceAlpha=0.15, LineStyle="none", DisplayName="This state's region");
plot(lower_bounds.alt, lower_bounds.data, "--k", LineWidth=1, DisplayName="Lower target bound");
plot(upper_bounds.alt, upper_bounds.data, "--k", LineWidth=1, DisplayName="Upper target bound");
plot(upper_bounds.alt, (lower_bounds.data + upper_bounds.data)/2, "--r", LineWidth=1, DisplayName="50% target bound");
plot(zero_logs.position(:,2), zero_logs.velocity(:,2), "-b", LineWidth=1, DisplayName="This state's upper bound");
plot(full_logs.position(:,2), full_logs.velocity(:,2), "-b", LineWidth=1, DisplayName="This state's  lower bound");
plot(const_logs.position(:,2), const_logs.velocity(:,2), LineWidth=1.5, DisplayName="Const. effort control");
plot(max_logs.position(:,2), max_logs.velocity(:,2), LineWidth=1.5, DisplayName="Max margin control");

xlim([min(lower_bounds.alt) 3300]);
ylim([0 max(upper_bounds.data)]);

legend;



nexttile([[1 1]]); hold on; grid on;
plot(const_logs.Time, const_logs.effort, DisplayName="Const. effort");
plot(const_logs.Time, const_logs.const_effort, "--", DisplayName="Const. effort vel bound percent");
plot(max_logs.Time, max_logs.effort, DisplayName="Max margin effort");
plot(max_logs.Time, max_logs.const_effort, "--", DisplayName="Max margin vel bound percent");

legend;