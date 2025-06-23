clear;
project_globals;

num_samples = 1000;
stored_vars = ["Lateral distance", "Altitude", ...
    "Lateral velocity", "Vertical velocity"];

% better to randomize wind inside the simulation using OR's Karman wind noise
orkopts.setWindSpeedAverage(7);
orkopts.setWindSpeedDeviation(3)
orkopts.setTimeStep(0.05);

% define varied parameters
sample_size = [num_samples 1];
rod_avg = deg2rad(4);
rod_spr = deg2rad(0.5);
rod_angles = rod_avg + rod_spr * (rand(sample_size) - 0.5); 

tmp_avg = 273.15 + 25;
tmp_spr = 10;
temperatures = tmp_avg + tmp_spr * randn(sample_size); 

wdir_offset_spr = deg2rad(20);
wdir_offsets = wdir_offset_spr * randn(sample_size);

% model mis-specified drag by taking the baseline drag table with ext=0
cd_spr = 0.1;
cd_scales = 1 + cd_spr * randn(sample_size);
baseline_params = vehicle_params("openrocket");
baseline_drag = table(baseline_params.cd_array.mach, ...
    baseline_params.cd_array.pick{"effort", 0}, ...
    VariableNames = ["MACH", "DRAG"]);
baseline_drag.MACH(1) = 0;

cases = table;
cases.rod_angle = rod_angles;
cases.temp = temperatures;
cases.wind_off = wdir_offsets;
cases.cd_scale = cd_scales;

% informational
cases.apogee = NaN(height(cases), 1); 
cases.on_time = NaN(height(cases), 1); % time at which airbrake turns on

% initial conditions
cases.position_init = NaN(height(cases), 2); % initial position [x, z]
cases.velocity_init = NaN(height(cases), 2); % initial velocity [xdot, zdot]

% cases.output = cell(height(cases),1);

for i_sim = 1:num_samples
    start = tic;
    orkopts.randomizeSeed();
    orkopts.setISAAtmosphere(false);
    orkopts.setLaunchRodAngle(cases.rod_angle(i_sim));
    orkopts.setWindDirection(orkopts.getLaunchRodDirection() + cases.wind_off(i_sim));
    orkopts.setLaunchTemperature(cases.temp(i_sim));

    dragdata = baseline_drag;
    dragdata.DRAG = dragdata.DRAG * cases.cd_scale(i_sim);
    
    data = doc.simulate(orksim, ...
        outputs = stored_vars, stop = "APOGEE", drag = dragdata);

    % Informational
    cases{i_sim, "apogee"} = max(data.Altitude);

    idx_on = find(data.("Vertical velocity") > vel_max, 1, "last") + 1;
    cases{i_sim, "on_time"} = seconds(data.Time(idx_on));
    
    % burnout is not garaunteeed to fall on a simulation sample time if the
    % time step is large enough
    evs = data.Properties.Events;
    burnout_time = evs.Time(evs.EventLabels == "BURNOUT");
    data_init = retime(data, burnout_time);
    % initial conditions for Simulink model
    cases{i_sim, "position_init"} = data_init{1, ["Lateral distance", "Altitude"]};
    cases{i_sim, "velocity_init"} = data_init{1, ["Lateral velocity", "Vertical velocity"]};

    fprintf("Finished %d of %d in %.2f sec\n", i_sim, num_samples, toc(start));
end

runs.("ork_" + num_samples) = cases;
