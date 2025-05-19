project_globals;

drag_fraction = 0.9;

simdata = doc.simulate(doc.sims(1), outputs = "ALL", stop = "APOGEE");
vehicle_data = get_vehicle_data(doc);
inits = get_initial_data(simdata);
brake_data = get_brake_data("ideal");
brake_data.const_brake = 1;
brake_data.brake_on = inits.t_0;

sim_file = pfullfile("sim", "sim_on_off");
simin = structs2inputs(sim_file, vehicle_data);
simin = structs2inputs(simin, brake_data);
simin = structs2inputs(simin, inits);
simin = simin.setModelParameter(FastRestart = "on", SimulationMode = "accelerator");

inputs = table;
inputs.brake_off = inits.t_0 + (3:0.5:17)';

cases = table2inputs(simin, inputs);
outputs = sim(cases);
reductions = max(simdata.Altitude) - [outputs.apogee];
most_reduction = drag_fraction * max(reductions);
time_to_fraction = interp1(reductions, inputs.brake_off, most_reduction);

set_param(simin.ModelName, FastRestart = "off");

timing_figure = figure(name = "Airbrake timing");
hold on; grid on;
plot(seconds(inputs.brake_off), reductions);
yline(0.9 * max(reductions), "--k", round(100*drag_fraction) + "% reduction", ...
    LabelVerticalAlignment = "bottom");
xline(seconds(time_to_fraction), ":k", round(time_to_fraction, 2) + " sec", ...
    LabelVerticalAlignment = "bottom", LabelOrientation = "horizontal");
xlabel("Off time");
ylabel("Apogee reduction");
ysecondarylabel("m");

fontsize(timing_figure, 9, "points");
export_at_size(timing_figure, "airbrake_timing.pdf", [420 250]);

