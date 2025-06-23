clear;

project_globals;

const_sim_path = pfullfile("sim", "sim_const");
altitudes = linspace(alt_start, apogee_target, 100);
make_bounds = false;
upper_name = "upper_bounds";
lower_name = "lower_bounds";

baseline_data = doc.simulate(orksim, outputs = "ALL", stop = "BURNOUT");
const_simin = structs2inputs(const_sim_path, vehicle_params("openrocket"));
const_simin = structs2inputs(const_simin, get_initial_data(baseline_data));
const_simin = structs2inputs(const_simin, struct(brake_on = 0, brake_off = 100));

if make_bounds || isempty(whos(luts, upper_name))
    const_simin = const_simin.setModelParameter(FastRestart = "on", ...
        SimulationMode = "accelerator");

    [uppers, lowers] = calc_bounds(const_simin, apogee_target, altitudes, 0);
    uppers = xarray(uppers, alt = altitudes);
    lowers = xarray(lowers, alt = altitudes);

    luts.(upper_name) = uppers;
    luts.(lower_name) = lowers;

    set_param(const_simin.ModelName, FastRestart = "off");
else
    uppers = luts.(upper_name);
    lowers = luts.(lower_name);
end

