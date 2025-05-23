clear;
project_globals;

simdata = doc.simulate(doc.sims(1), outputs = "ALL", stop = "APOGEE");
vehicle_data = vehicle_params(doc);
inits = get_initial_data(simdata);
inits.dt = 0.01;
ctrl.control_mode = "const";
ctrl.const_brake = 0;
ctrl.controller_rate = 1/inits.dt;

simin = structs2inputs(sim_file, vehicle_data);
simin = structs2inputs(simin, inits);
simin = structs2inputs(simin, ctrl);
simin = simin.setModelParameter(FastRestart = "on", SimulationMode = "accelerator");

% create array of inputs where the brake is fully on with different areas
simin_on = simin.setVariable(const_brake = 1);

% input table just has one variable, plate area
inputs = table;
inputs.PLATE_AREA = vehicle_data.PLATE_AREA * 0.1 * (1:15)';
simins_on = table2inputs(simin_on, inputs); % one input per table row

baseline = sim(simin);

cases = sim(simins_on);
efforts = baseline.apogee - [cases.apogee];
set_param(simin.ModelName, FastRestart = "off");

effort_figure = figure(name = "Airbrake area design curve");
grid on; hold on;
plot(1e4 * inputs.PLATE_AREA, efforts, "+");
yline(max(simdata.Altitude) - apogee_target, "--k", "Required");
xlabel("Fully-extended area");
xsecondarylabel("cm^2");
ylabel("Apogee reduction");
ysecondarylabel("m");



export_at_size(effort_figure, "effort_curve.pdf", [420 250]);
