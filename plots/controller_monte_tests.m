project_globals;

or_sim = doc.sims(1);
or_sim_opts = or_sim.getOptions();
sim_file = pfullfile("sim", "sim_controller");

%% Monte Carlo OpenRocket Inputs

ctrl_under_test = "exaust";
% ctrl_under_test = "quantile_effort";
% ctrl_under_test = "quantile_tracking";

temperature_mean = 20;
temperature_range = 5;
wind_mean = 10;
wind_range = 5;
angle_mean = deg2rad(85); 
angle_range = deg2rad(0.5);
cd_std = 0.1;

controller_data = struct;
switch ctrl_under_test
    case "exhaust"
        controller_data.control_mode = "exhaust";

        params = luts.exhaust_100_by_100;
        controller_data.baro_lut = xarray2lut(params.lut);
    case "quantile_effort"
        controller_data.control_mode = "quant";
    case "quantile_tracking"
        controller_data.control_mode = "track";
    otherwise
        error ("Unrecognzied case %s", ctrl_under_test);
end


simin = structs2inputs(simin, controller_data);

ordata = doc.simulate(doc.sims(1), outputs = "ALL", stop = "APOGEE");
sim_file = pfullfile("sim", "sim_controller");
ideal_vehicle = vehicle_params(doc);
ideal_brake = get_brake_data("ideal");
inits = get_initial_data(ordata);
simin_baseline = structs2inputs(sim_file, inits);
simin_baseline = structs2inputs(simin_baseline, ideal_vehicle);
simin_baseline = structs2inputs(simin_baseline, ideal_brake);

params = luts.exhaust_100_by_100;
simin_baseline = simin_baseline.setVariable(dt = 0.01);
simin_baseline = simin_baseline.setVariable(control_mode = "exhaust");
simin_baseline = simin_baseline.setVariable(baro_lut = xarray2lut(params.lut));

simin_noisy = structs2inputs(simin_baseline, get_brake_data("noisy"));

drag_error = 0.1;
drag_over_vehicle = ideal_vehicle;
drag_over_vehicle.DRAG_DATA.DRAG = (1-drag_error) * drag_over_vehicle.DRAG_DATA.DRAG;
drag_over_vehicle.PLATE_CD = (1-drag_error)*ideal_brake.PLATE_CD;

drag_under_vehicle = ideal_vehicle;
drag_under_vehicle.DRAG_DATA.DRAG = (1+drag_error) * drag_under_vehicle.DRAG_DATA.DRAG;
drag_under_vehicle.PLATE_CD = (1+drag_error)*ideal_brake.PLATE_CD;

simin_over = structs2inputs(simin_noisy, drag_over_vehicle);
simin_under = structs2inputs(simin_noisy, drag_under_vehicle);

simins = [simin_baseline; simin_noisy; simin_over; simin_under];
names = ["Ideal", "Noisy", "C_D overestimated", "C_d underestimated"];
simouts = sim(simins);

exhaust_test_fig = figure(name = "Exaustive LUT tests")
layout = tiledlayout("vertical");

phase_ax = nexttile([2 1]); hold on; grid on;
plot(luts.uppers_100, "--k", HandleVisibility = "off");
plot(luts.lowers_100, "--k", HandleVisibility = "off");
xlabel("Altitude"); xsecondarylabel("m AGL");
ylabel("Vertical velocity"); ysecondarylabel("m/s");
legend(phase_ax, ...
    Location = "northoutside", Orientation = "horizontal", NumColumns = 2);

effort_ax = nexttile; hold on; grid on;
ylabel("Extension");
xlabel("Time");
xregion(seconds([5.5 12.5]));


for i_simout = 1:length(simouts)
    logs = extractTimetable(simouts(i_simout).logsout);
    logs = fillmissing(logs, "previous");
    logs = logs(timerange(logs.Time(1) + seconds(2), seconds(Inf)), :);

    plot(phase_ax, logs.altitude_est, logs.velocity_est, ...
        DisplayName = names(i_simout), SeriesIndex = i_simout);
    plot(effort_ax, logs.Time, logs.extension, ...
        DisplayName = names(i_simout), SeriesIndex = i_simout);
end

export_sized(exhaust_test_fig, "exhaust_tests.pdf", [420 530]);



