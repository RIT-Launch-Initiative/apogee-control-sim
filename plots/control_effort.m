clear;
project_globals;

simdata = doc.simulate(orksim, outputs = "ALL", stop = "APOGEE", atmos = airdata);
vehicle_data = vehicle_params("openrocket", rocket_file, sim_name);
inits = get_initial_data(simdata);
ctrl.control_mode = "const";
ctrl.brake_on = inits.t_0;
ctrl.brake_off = 100; % arbitrary and large

simin = structs2inputs("sim_const", vehicle_data);
simin = structs2inputs(simin, inits);
simin = structs2inputs(simin, ctrl);
simin = simin.setModelParameter(SimulationMode = "accelerator");

cases = table;
cases.const_brake = linspace(0, 1, 20)';
simins = table2inputs(simin, cases);

areas = cases.const_brake * vehicle_data.plate_drag_area;
simouts = sim(simins, UseFastRestart = "on");
efforts = simouts(1).apogee - [simouts.apogee];

areas_smooth = linspace(areas(1), areas(end), 100);
efforts_smooth = interp1(areas, efforts, areas_smooth);
[~, areas_smooth_index] = min(abs(areas_smooth - 23.39e-4));
current_apogee_reduction = efforts_smooth(areas_smooth_index);

effort_figure = figure(name = "Airbrake area design curve");
grid on; hold on;
plot(1e4 * areas, efforts, "+");
plot([23.39, 23.39, 0], [0, current_apogee_reduction, current_apogee_reduction]);
text(0.5, current_apogee_reduction+25, sprintf('%.0f', current_apogee_reduction), "Color", "red");
% yline(max(simdata.Altitude) - apogee_target, "--k", "Required");
xlabel("Fully-extended drag area");
xsecondarylabel("cm^2");
ylabel("Apogee reduction");
ysecondarylabel("m");
legend("Calculated", "Current Reduction");
title("IREC M3400 Apogee Reduction");
effort_figure.WindowStyle = 'normal';
effort_figure.Units = "pixels";
effort_figure.Position = [0 0 400 300];

% print2size(effort_figure, fullfile(graphics_path, "effort_curve.pdf"), 1.5*[420 250]);
