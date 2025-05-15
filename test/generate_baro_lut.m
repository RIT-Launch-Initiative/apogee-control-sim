clear;

run_monte = false;

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
vehicle_data = get_vehicle_data(doc);
inits.t_0 = 0;
inits.dt = 0.01;

simin = structs2inputs(sim_file, vehicle_data);
simin = structs2inputs(simin, inits);
% set_param(simin.ModelName, FastRestart = "off");
% % accelerator mode generates a "simulation target" that runs faster
% simin = simin.setModelParameter(SimulationMode = "accelerator");
% % use FastRestart to prevent model recompilation
% simin = simin.setModelParameter(FastRestart = "on");
simin = setup_const_sim(simin);

N_points = 100;
altitudes = linspace(1000, apogee_target, N_points); % [m]
velocities = linspace(0, 270, N_points); % [m/s]

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

figure;
imagesc(lut, cmap = "parula", clabel = "Extension");
