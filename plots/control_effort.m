clear;
project_globals;

simdata = doc.simulate(orksim, outputs = "ALL", stop = "APOGEE");
vehicle_data = vehicle_params("openrocket");
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

effort_figure = figure(name = "Airbrake area design curve");
grid on; hold on;
plot(1e4 * areas, efforts, "+");
yline(max(simdata.Altitude) - apogee_target, "--k", "Required");
xlabel("Fully-extended drag area");
xsecondarylabel("cm^2");
ylabel("Apogee reduction");
ysecondarylabel("m");

print2size(effort_figure, fullfile(graphics_path, "effort_curve.pdf"), 1.5*[420 250]);
