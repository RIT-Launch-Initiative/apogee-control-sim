project_globals;

num_samples = 400;
stored_vars = ["Lateral distance", "Altitude", ...
               "Lateral velocity", "Vertical velocity", ...
               "Lateral acceleration", "Vertical acceleration", ...
               "Vertical orientation (zenith)", ...
               "Wind velocity"];

% better to randomize wind inside the simulation using OR's Karman wind noise
orkopts.setWindSpeedAverage(9);
orkopts.setWindSpeedDeviation(4.25)
orkopts.setTimeStep(0.05);

% define varied parameters
sample_size = [num_samples 1];
rod_avg = deg2rad(6);
rod_spr = deg2rad(2);
rod_angles = rod_avg + rod_spr * 2 * (rand(sample_size) - 0.5); 

tmp_avg = 273.15 + 25;
tmp_spr = 10;
temperatures = tmp_avg + tmp_spr * randn(sample_size); 

wdir_offset_spr = deg2rad(20);
wdir_offsets = wdir_offset_spr * randn(sample_size);

% model mis-specified drag by taking the baseline drag table with ext=0
cd_spr = 0.1;
cd_scales = 1 + cd_spr * randn(sample_size);
baseline_params = vehicle_params("openrocket", rocket_file, sim_name);
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
cases.wind_speed = NaN(height(cases), 1);
cases.apogee = NaN(height(cases), 1);

cases.orkdata_for_simulink = cell(height(cases),1);

for i_sim = 1:num_samples
    start = tic;
    orkopts.randomizeSeed();
    % orkopts.setISAAtmosphere(false);
    orkopts.setLaunchRodAngle(cases.rod_angle(i_sim));
    orkopts.setWindDirection(orkopts.getLaunchRodDirection() + cases.wind_off(i_sim));
    orkopts.setLaunchTemperature(cases.temp(i_sim));

    dragdata = baseline_drag;
    dragdata.DRAG = dragdata.DRAG * cases.cd_scale(i_sim);
    
    orkdata = doc.simulate(orksim, ...
        outputs = stored_vars, stop = "APOGEE", drag = dragdata, atmos = airdata);

    % Informational
    cases{i_sim, "wind_speed"} = orkdata{eventfilter("LAUNCHROD"), "Wind velocity"};
    cases{i_sim, "apogee"} = max(orkdata.Altitude);

    % store state time history to burnout
    orkdata_LAUNCH_to_BURNOUT = orkdata(timerange(eventfilter("LAUNCH"), eventfilter("BURNOUT")),:);
    orkdata_for_simulink = orkdata_LAUNCH_to_BURNOUT(:,[]);
    orkdata_for_simulink.position = [orkdata_LAUNCH_to_BURNOUT.("Lateral distance") orkdata_LAUNCH_to_BURNOUT.Altitude];
    orkdata_for_simulink.velocity = [orkdata_LAUNCH_to_BURNOUT.("Lateral velocity") orkdata_LAUNCH_to_BURNOUT.("Vertical velocity")];
    orkdata_for_simulink.acceleration = [orkdata_LAUNCH_to_BURNOUT.("Lateral acceleration") orkdata_LAUNCH_to_BURNOUT.("Vertical acceleration")];
    orkdata_for_simulink.pitch = orkdata_LAUNCH_to_BURNOUT.("Vertical orientation (zenith)");
    orkdata_for_simulink(seconds(0), :) = orkdata_for_simulink(1,:); % zero out OR weirdness at time zero
    orkdata_for_simulink = sortrows(orkdata_for_simulink);
    orkdata_for_simulink(1:2, :).position = [0 0; 0 0];
    orkdata_for_simulink(1:2, :).velocity = [0 0; 0 0];
    orkdata_for_simulink(1:2, :).acceleration = [0 0; 0 0];
    cases{i_sim, "orkdata_for_simulink"} = {orkdata_for_simulink};

    fprintf("Finished %d of %d in %.2f sec\n", i_sim, num_samples, toc(start));
end

runs.("ork_" + num_samples) = cases;
