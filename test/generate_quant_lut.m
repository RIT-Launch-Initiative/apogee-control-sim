clear;
generate_table = true;

%% DEFINE INPUT FILES
project_globals;

%% LUT RANGES

N_alts = 100;
N_vels = 10;
altitudes = linspace(1200, apogee_target - 10, N_alts); % [m]
quantiles = linspace(0, 1, N_vels);

if generate_table
    sim_file = pfullfile("sim", "sim_const");
    vehicle_data = get_vehicle_data(doc);
    inits.t_0 = 0;
    inits.dt = 0.01;
    inits.controller_rate = 1/inits.dt;

    simin = structs2inputs(sim_file, vehicle_data);
    simin = structs2inputs(simin, inits);
    simin = simin.setModelParameter(SimulationMode = "accelerator", FastRestart = "on");

    % instead of (altitudes, velocities) because this is faster
    extensions = zeros(N_vels, N_alts);

    % find upper and lower bounds per altitude to 
    [uppers, lowers] = find_reachable_states(simin, apogee_target, altitudes, 0);

    for i_alt = 1:N_alts
        alt = altitudes(i_alt);
        lower = lowers(i_alt);
        upper = uppers(i_alt);

        simin = simin.setVariable(position_init = [0; alt]);
        for i_quant = 1:N_vels
            start = tic;

            vvel = lower + (upper - lower) * quantiles(i_quant);
            simin = simin.setVariable(velocity_init = [0; vvel]);
            extensions(i_quant, i_alt) = find_extension(apogee_target, simin, quantiles(i_quant));

            time = toc(start);
            fprintf("Finished optimization %d of %d in %.2f sec\n", ...
                i_quant + (i_alt - 1) * N_vels, N_alts * N_vels, time);
        end
    end

    set_param(simin.ModelName, FastRestart = "off");

    upper_lut = xarray(uppers, alt = altitudes);
    lower_lut = xarray(lowers, alt = altitudes);
    quant_lut = xarray(extensions, quant = quantiles, alt = altitudes);

    luts.(sprintf("quant_%d_by_%d", N_vels, N_alts)) = quant_lut;
    luts.("uppers_" + N_alts) = upper_lut;
    luts.("lowers_" + N_alts) = lower_lut;
else
    quant_lut = luts.(sprintf("quant_%d_by_%d", N_vels, N_alts));
    upper_lut = luts.("uppers_" + N_points);
    lower_lut = luts.("lowers_" + N_points);
end

% lut_figure = figure(name = "Lookup table");
% imagesc(lut, cmap = "parula", clabel = "Control effort [0-1]");
% xlabel("Altitude");
% xsecondarylabel("m AGL");
% ylabel("Vertical velocity");
% ysecondarylabel("m/s");
%
% export_at_size(lut_figure, "exhaustive_lut.pdf", [500 400]);
%
%% Test table
sim_file = pfullfile("sim", "sim_controller");
vehicle_data = get_vehicle_data(doc);
data = doc.simulate(doc.sims(1), outputs = "ALL", stop = "APOGEE");
inits = get_initial_data(data);
inits.dt = 0.01;

ctrl.control_mode = "quant";
ctrl.observer_rate = 100;
ctrl.controller_rate = 10;
ctrl.upper_bound_lut = xarray2lut(upper_lut);
ctrl.lower_bound_lut = xarray2lut(lower_lut);
ctrl.quantile_lut = xarray2lut(quant_lut);

simin = structs2inputs(sim_file, vehicle_data);
simin = structs2inputs(simin, inits);
simin = structs2inputs(simin, ctrl);

simout = sim(simin);
logs = extractTimetable(simout.logsout);
logs = fillmissing(logs, "previous");

fprintf("Achieved apogee: %.1f\n", simout.apogee);

%
% simout_figure = figure(name = "Motion");
% layout = tiledlayout("vertical");
% layout.TileSpacing = "tight";
%
% nexttile; hold on; grid on;
% plot(data.Time, data.Altitude, DisplayName = "Baseline");
% plot(logs.Time, logs.position(:,2), DisplayName = "Simulated");
% % plot(logs.Time, logs.altitude_measured, DisplayName = "Measured");
% % plot(logs.Time, logs.altitude_est, DisplayName = "Estimated")
% legend;
% ylabel("Altitude");
%
% nexttile; hold on; grid on;
% plot(data.Time, data.("Vertical velocity"), DisplayName = "Baseline");
% plot(logs.Time, logs.velocity(:, 2), DisplayName = "Simulated");
% % plot(logs.Time, logs.vvel_est, DisplayName = "Estimated");
% legend;
% ylabel("Vertical Velocity");
%
% nexttile; hold on; grid on;
% plot(logs.Time, logs.extension);
% ylabel("Control effort")
%
% nexttile; hold on; grid on;
% plot(data.Time, data.("Drag force"), DisplayName = "Baseline");
% plot(logs.Time, logs.drag_force, DisplayName = "Simulated");
% ylabel("Drag force");
%
% phase_traj_figure = figure(name = "Basic phase trajectory");
% hold on; grid on;
% plot(data.Altitude, data.("Vertical velocity"), DisplayName = "Baseline");
% plot(logs.position(:,2), logs.velocity(:, 2), DisplayName = "Controlled");
% plot(altitudes, uppers, "--k", HandleVisibility = "off");
% plot(altitudes, lowers, "--k", Handlevisibility = "off");
% xlim([-Inf apogee_target]);
% xlabel("Altitude");
% xsecondarylabel("m AGL");
% ylabel("Vertical velocity");
% ysecondarylabel("m/s");
% legend;
%
% export_at_size(phase_traj_figure, "basic_phase_trajs.pdf", [500 400]);
%
