clear;
project_globals;

rundata = matfile(pfullfile("data", "runs.mat"), Writable = true);
orksim = doc.sims("MATLAB");
orkopts = orksim.getOptions();

num_samples = 1000;

% better to randomize wind inside the simulation using OR's Karman wind noise
orkopts.setWindSpeedAverage(7);
orkopts.setWindSpeedDeviation(3)
orkopts.setTimeStep(0.05);

% define varied parameters
rod_avg = deg2rad(85);
rod_spr = deg2rad(0.5);
rod_angles = normrnd(rod_avg, rod_spr, [num_samples 1]);

tmp_avg = 273.15 + 25;
tmp_spr = 10;
temperatures = normrnd(tmp_avg, tmp_spr, [num_samples 1]);

wdir_offset_spr = deg2rad(20);
wdir_offsets = normrnd(0, wdir_offset_spr, [num_samples 1]);

% model mis-specified drag by taking the baseline drag table with ext=0
cd_spr = 0.05;
cd_scales = normrnd(1, cd_spr, [num_samples 1]);
baseline_params = vehicle_params("openrocket");
baseline_drag = table(baseline_params.cd_array.mach, ...
    baseline_params.cd_array.pick{"effort", 0}, ...
    VariableNames = ["MACH", "DRAG"]);
baseline_drag.MACH(1) = 0;

cases = table(rod_angles, temperatures, wdir_offsets, cd_scales);
cases.Properties.VariableNames = ["rod_angle", "temp", "wind_off", "cd_scale"];
cases.output = cell(height(cases),1);

for i_sim = 1:num_samples
    start = tic;
    orkopts.randomizeSeed();
    orkopts.setISAAtmosphere(false);
    orkopts.setLaunchRodAngle(cases.rod_angle(i_sim));
    orkopts.setWindDirection(orkopts.getLaunchRodDirection() + cases.wind_off(i_sim));
    orkopts.setLaunchTemperature(cases.temp(i_sim));

    dragdata = baseline_drag;
    dragdata.DRAG = dragdata.DRAG * cases.cd_scale(i_sim);
    
    cases.output{i_sim} = doc.simulate(orksim, outputs = "ALL", stop = "APOGEE", drag = dragdata);

    fprintf("Finished %d of %d in %.2f sec\n", i_sim, num_samples, toc(start));
end

rundata.("ork_" + num_samples) = cases;
