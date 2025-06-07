clear;

project_globals;

const_sim_path = pfullfile("sim", "sim_const");
altitudes = linspace(1200, apogee_target, 100);
make_bounds = false;
upper_name = "upper_bounds";
lower_name = "lower_bounds";

baseline_data = doc.simulate(doc.sims("MATLAB"), outputs = "ALL", stop = "BURNOUT");
const_simin = structs2inputs(const_sim_path, vehicle_params("openrocket"));
const_simin = structs2inputs(const_simin, get_initial_data(baseline_data));
const_simin = structs2inputs(const_simin, struct(brake_on = 0, brake_off = 100));

if make_bounds || isempty(whos(cache, upper_name))
    const_simin = const_simin.setModelParameter(FastRestart = "on", SimulationMode = "accelerator");

    [uppers, lowers] = find_reachable_states(const_simin, apogee_target, altitudes, 0);
    uppers = xarray(uppers, alt = altitudes);
    lowers = xarray(lowers, alt = altitudes);
    cache.(upper_name) = uppers;
    cache.(lower_name) = lowers;

    set_param(const_simin.ModelName, FastRestart = "off");
else
    uppers = cache.(upper_name);
    lowers = cache.(lower_name);
end

