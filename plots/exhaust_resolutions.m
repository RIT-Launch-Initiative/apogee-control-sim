project_globals;

brake_mode = "noisy";
brake_drag = "nominal";
sim_file = pfullfile("sim", "sim_controller");

% doc.sims(1).getOptions().setWindSpeedDeviation(0);
ordata = doc.simulate(doc.sims(1), outputs = "ALL", stop = "APOGEE");
vehicle_data = vehicle_params(doc);
brake_data = get_brake_data(brake_mode);

if brake_drag == "underestimated"
    brake_data.PLATE_CD = 1.4;
elseif brake_drag == "overestimated"
    brake_data.PLATE_CD = 1.0;
end

simin = structs2inputs(sim_file, vehicle_params(doc));
simin = structs2inputs(simin, get_brake_data(brake_mode));
simin = structs2inputs(simin, get_initial_data(ordata));
simin = simin.setVariable(dt = 0.01);
simin = simin.setVariable(control_mode = "exhaust");

nums_alt = [20 50 100];
nums_vel = [20 50 100];
[grid_vel, grid_alt] = ndgrid(nums_vel, nums_alt);
target_names = compose("exhaust_%d_by_%d", grid_vel(:), grid_alt(:));

ctrls = struct;
for i_case = 1:length(target_names)
    params = luts.(target_names(i_case));
    ctrls(i_case).baro_lut = xarray2lut(params.lut);
end

cases = structs2inputs(simin, ctrls);
outputs = sim(cases);

results = reshape(vertcat(outputs.apogee), size(grid_vel));
errors = results - apogee_target;
errors_figure = figure(name = "Errors");
bars = bar(categorical(nums_vel), errors);
names = num2cell(nums_alt + " altitude points")
[bars.DisplayName] = deal(names{:});
legend;
xlabel("Velocity points");
ylabel("Altitude error");
ysecondarylabel("m");


% perf_figure = figure(name = "Airbrake performance under ideal conditions");
% layout = tiledlayout("vertical");
% time_hist = nexttile; 
% hold on; grid on; 
% xlabel("Time");
% ylabel("Altitude"); ysecondarylabel("m AGL");
% legend(Location = "northoutside", Orientation = "horizontal");
%
% effort_hist = nexttile;
% hold on; grid on;
% xlabel("Time");
% ylabel("Controller effort");
%
%
% phase_traj = nexttile([2 1]); 
% hold on; grid on; 
% ylabel("Vertical velocity"); ysecondarylabel("m/s");
% xlabel("Altitude"); ysecondarylabel("m AGL");
%
%
% for i_set = 1:length(nums_alt)
%     target_name = sprintf("exhaust_%d_by_%d", nums_vel(i_set), nums_alt(i_set));
%     disp_name = sprintf("%d by %d", nums_vel(i_set), nums_alt(i_set));
%
%     ctrl = luts.(target_name);
%     simin = simin.setVariable(baro_lut = xarray2lut(ctrl.lut));
%
%     simout = sim(simin);
%     logs = extractTimetable(simout.logsout);
%     logs = fillmissing(logs, "previous");
%
%     errors(i_set) = simout.apogee - apogee_target;
%     plot(time_hist, logs.Time, logs.position(:,2), DisplayName = disp_name);
%     plot(effort_hist, logs.Time, logs.effort);
%     plot(phase_traj, logs.position(:,2), logs.velocity(:,2));
% end
%
% results = table(nums_alt', nums_vel', errors', ...
%     VariableNames = ["num_alt", "num_vel", "error"]);
% disp(results);
%
