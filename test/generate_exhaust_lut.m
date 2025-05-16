clear;

run_monte = false;
generate_table = true;

%% DEFINE INPUT FILES
project_globals;

%% MONTE CARLO
if run_monte
    N_sims = 100;
    wind_av = 7;
    wind_std = 3;

    rod_av = deg2rad(5);
    rod_rng = deg2rad(2);
    rod_angles = (rand(N_sims, 1) - 0.5) * rod_rng + rod_av;

    temp_av = 273.15 + 20;
    temp_rng = 10;
    temps = (rand(N_sims, 1) - 0.5) * temp_rng + temp_av;

    required_outputs = ["Altitude", "Vertical velocity", "Lateral velocity"];
    sampled_altitudes = 800:50:2500;

    outputs = cell(N_sims, 1);
    vvels = NaN(N_sims, length(sampled_altitudes));
    hvels = NaN(N_sims, length(sampled_altitudes));

    sim = doc.sims(1);
    opts = sim.getOptions();
    opts.setLaunchIntoWind(true);
    opts.setWindSpeedDeviation(wind_std);
    opts.setWindSpeedAverage(wind_av);
    opts.setTimeStep(0.05);

    for i_sim = 1:length(outputs)
        opts.setLaunchRodAngle(rod_angles(i_sim));
        opts.setLaunchTemperature(temps(i_sim));

        data = doc.simulate(sim, outputs = required_outputs, stop = "APOGEE");
        outputs{i_sim} = data;

        vvels(i_sim, :) = interp1(data.Altitude, data.("Vertical velocity"), ...
        sampled_altitudes, "linear", NaN);
        hvels(i_sim, :) = interp1(data.Altitude, data.("Lateral velocity"), ...
        sampled_altitudes, "linear", NaN);

        fprintf("Finished run %d of %d\n", i_sim, length(outputs));
    end

    figure(name = "Flight condition spreads");
    layout = tiledlayout("vertical");
    vvel_ax = nexttile; hold on; grid on;
    hvel_ax = nexttile; hold on; grid on;

    for i_sim = 1:length(outputs)
        plot(vvel_ax, sampled_altitudes, vvels(i_sim, :), "+", Color = [0 0.44 0.74 0.2]);
        plot(hvel_ax, sampled_altitudes, hvels(i_sim, :), "+", Color = [0 0.44 0.74 0.2]);
    end
end

%% LUT RANGES

N_points = 100;
altitudes = linspace(1000, apogee_target - 10, N_points); % [m]
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
xlim([1200 Inf]);

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
xlim([1200 apogee_target]);
xlabel("Altitude");
xsecondarylabel("m AGL");
ylabel("Vertical velocity");
ysecondarylabel("m/s");
legend;

export_at_size(phase_traj_figure, "basic_phase_trajs.pdf", [500 400]);

