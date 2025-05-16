clear;
generate_table = true;

%% DEFINE INPUT FILES
project_globals;

%% LUT RANGES

N_points = 100;
altitudes = linspace(1200, apogee_target - 10, N_points); % [m]
velocities = linspace(0, 270, N_points); % [m/s]

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
    [initial_velocities, initial_altitudes] = ndgrid(velocities, altitudes); 
    extensions = zeros(size(initial_altitudes));

    % find upper and lower bounds per altitude to 
    [uppers, lowers] = find_reachable_states(simin, apogee_target, altitudes, 0);

    for i_sim = 1:numel(extensions)
        start = tic;
        this_sim = struct;
        alt = initial_altitudes(i_sim);
        vvel = initial_velocities(i_sim);

        % default values for states that can't reach apogee target
        % use (altitude == alt) instead of i_sim because uppers() and lowers() are 1xN_alt rows
        if (vvel >= uppers(altitudes == alt))
            extensions(i_sim) = 1;
            continue;
        elseif (vvel <= lowers(altitudes == alt))
            extensions(i_sim) = 0;
            continue;
        end


        simin = simin.setVariable(position_init = [0; alt]);
        simin = simin.setVariable(velocity_init = [0; vvel]);
        this_sim.position_init = [0; initial_altitudes(i_sim)];
        this_sim.velocity_init = [0; initial_velocities(i_sim)];
        si = structs2inputs(simin, this_sim);

        if i_sim == 1
            guess = 0.5;
        else
            guess = extensions(i_sim-1);
        end

        extensions(i_sim) = find_extension(apogee_target, si, guess);
        time = toc(start);
        fprintf("Finished optimization %d of %d in %.2f sec\n", i_sim, numel(extensions), time);
    end

    set_param(simin.ModelName, FastRestart = "off");

    lut = xarray(extensions, vel = velocities, alt = altitudes);
    luts.("lut_" + N_points) = lut;
    luts.("uppers_" + N_points) = uppers;
    luts.("lowers_" + N_points) = lowers;
else
    lut = luts.("lut_" + N_points);
    uppers = luts.("uppers_" + N_points);
    lowers = luts.("lowers_" + N_points);
end

lut_figure = figure(name = "Lookup table");
imagesc(lut, cmap = "parula", clabel = "Control effort [0-1]");
xlabel("Altitude");
xsecondarylabel("m AGL");
ylabel("Vertical velocity");
ysecondarylabel("m/s");

export_at_size(lut_figure, "exhaustive_lut.pdf", [500 400]);

%% Test table
sim_file = pfullfile("sim", "sim_controller");
vehicle_data = get_vehicle_data(doc);
data = doc.simulate(doc.sims(1), outputs = "ALL", stop = "APOGEE");
inits = get_initial_data(data);
inits.dt = 0.01;

ctrl.control_mode = "exhaust";
ctrl.observer_rate = 100;
ctrl.controller_rate = 10;
ctrl.baro_lut = xarray2lut(lut);

simin = structs2inputs(sim_file, vehicle_data);
simin = structs2inputs(simin, inits);
simin = structs2inputs(simin, ctrl);

simout = sim(simin);
logs = extractTimetable(simout.logsout)

fprintf("Achieved apogee: %.1f\n", simout.apogee);

simout_figure = figure(name = "Motion");
layout = tiledlayout("vertical");
layout.TileSpacing = "tight";

nexttile; hold on; grid on;
plot(data.Time, data.Altitude, DisplayName = "Baseline");
plot(logs.Time, logs.position(:,2), DisplayName = "Simulated");
% plot(logs.Time, logs.altitude_measured, DisplayName = "Measured");
% plot(logs.Time, logs.altitude_est, DisplayName = "Estimated")
legend;
ylabel("Altitude");

nexttile; hold on; grid on;
plot(data.Time, data.("Vertical velocity"), DisplayName = "Baseline");
plot(logs.Time, logs.velocity(:, 2), DisplayName = "Simulated");
% plot(logs.Time, logs.vvel_est, DisplayName = "Estimated");
legend;
ylabel("Vertical Velocity");

nexttile; hold on; grid on;
plot(logs.Time, logs.extension);
ylabel("Control effort")

nexttile; hold on; grid on;
plot(data.Time, data.("Drag force"), DisplayName = "Baseline");
plot(logs.Time, logs.drag_force, DisplayName = "Simulated");
ylabel("Drag force");

phase_traj_figure = figure(name = "Basic phase trajectory");
hold on; grid on;
plot(data.Altitude, data.("Vertical velocity"), DisplayName = "Baseline");
plot(logs.position(:,2), logs.velocity(:, 2), DisplayName = "Controlled");
plot(altitudes, uppers, "--k", HandleVisibility = "off");
plot(altitudes, lowers, "--k", Handlevisibility = "off");
xlim([-Inf apogee_target]);
xlabel("Altitude");
xsecondarylabel("m AGL");
ylabel("Vertical velocity");
ysecondarylabel("m/s");
legend;

export_at_size(phase_traj_figure, "basic_phase_trajs.pdf", [500 400]);

