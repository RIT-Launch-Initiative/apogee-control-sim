clear; 
project_globals;

% orkopts.setWindSpeedDeviation(0);
orkdata = doc.simulate(orksim, stop = "APOGEE", outputs = "ALL");
orkdata = mergevars(orkdata, ["Lateral acceleration", "Vertical acceleration"], "accel_fixed");

inputs = orkdata(:, "accel_fixed")
vehicle_info = vehicle_params("openrocket");
accel_info = accel_params("noisy");



simin = structs2inputs(pfullfile("sim", "accel_processing"), vehicle_info);
simin = structs2inputs(simin, accel_info);
simin =


orkdata = orkdata(timerange(seconds(-Inf), orkdata.Time(end) - seconds(0.5)), :);
orkdata.("Specific force") = ...
    (orkdata.Thrust - orkdata.("Drag force") .* cos(orkdata.("Angle of attack"))) ...
    ./ orkdata.("Mass");
% orkdata.("Calculated bias") = orkdata.("Specific force") .* ...
%     (sin(orkdata.("Vertical orientation (zenith)")) - 1) + orkdata.("Gravitational acceleration");

accel_err = figure(name = "Accelerometer error");
layout = tiledlayout(2,1);
layout.TileSpacing = "tight";
nexttile; hold on; grid on;
plot(orkdata.Time, orkdata.("Specific force"), DisplayName = "Measurement");
plot(orkdata.Time, orkdata.("Vertical acceleration"), DisplayName = "Vertical acceleration");
ylabel("Acceleration");
ysecondarylabel("m/s^2")
legend;
nexttile; hold on; grid on;
plot(orkdata.Time, orkdata.("Gravitational acceleration"), DisplayName = "Gravity");
plot(orkdata.Time, orkdata.("Specific force") - orkdata.("Vertical acceleration"), ...
    DisplayName = "Bias");
ylabel("Acceleration");
ysecondarylabel("m/s^2")
xlabel("Time");
legend;

% simin = structs2inputs("sim_controller", vehicle_params("openrocket"));
% simin = structs2inputs(simin, baro_params("ideal"));
% simin = structs2inputs(simin, accel_params("ideal"));
% simin = 
% no airbrake - measurement only
% ctrl.control_mode = "const";
% ctrl.const_brake = 0;
% ctrl.brake_on = 0;
% ctrl.brake_off = 100;

print2size(accel_err, fullfile(graphics_path, "accel_bias.pdf"), [700 400]);
