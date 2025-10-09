clear;
project_globals;

sim_file = pfullfile("sim", "sim_altimeter");
input_rate = 100; % [Hz]
output_rate = 10; % [Hz]

% use "low power" mode - pressure x2 temperature x1
BARO_LSB = 1.32; % [Pa]
BARO_COV = 2.5^2; % [Pa]
BARO_RATE = input_rate
% BARO_QUANT = 1e-10; % [Pa]
% BARO_RMSN = 0; % [Pa]
GROUND_LEVEL = doc.sims(1).getOptions().getLaunchAltitude();

data = doc.simulate(doc.sims(1), outputs = "ALL", atmos = airdata);
position = data(:, ["Lateral distance", "Altitude"]);
position = mergevars(position, ["Lateral distance", "Altitude"]);

t_0 = seconds(data.Time(1));
t_f = seconds(data.Time(end));
dt = 1/input_rate;

filter_order = 4;
pos_cutoff = 20;
vel_cutoff = 10;
[pos_num, pos_den] = butter(filter_order, 2*pos_cutoff/input_rate);
[vel_num, vel_den] = butter(filter_order, 2*vel_cutoff/input_rate);
% N_pos = input_rate / output_rate;
vel_avg = input_rate / output_rate;
% N_vel = 1;

simout = sim(sim_file);
logs = extractTimetable(simout.logsout);
logs = fillmissing(logs, "previous");

% modify SeriesIndex so that we can plot lines out-of-order to put the true
% data in the middle but keep the default blue-red-yellow color order

true_args = {"DisplayName", "True", "SeriesIndex", 1};
meas_args = {"DisplayName", "Measured", "SeriesIndex", 3, "LineWidth", 0.25};
est_args = {"DisplayName", "Estimated", "SeriesIndex", 2};

figure;
layout = tiledlayout(2,2);

cols = colororder;

% nexttile; hold on; grid on;
% plot(data.Time, data.("Air pressure"), true_args{:});
% stairs(logs.Time, logs.pressure_meas, meas_args{:});
% legend;

data_ax = nexttile; hold on; grid on;
stairs(logs.Time, logs.altitude_meas, meas_args{:});
plot(data.Time, data.Altitude, true_args{:});
stairs(logs.Time, logs.altitude_est, est_args{:});
ylabel("Altitude");
ysecondarylabel("m AGL");

nexttile; hold on; grid on;
stairs(logs.Time, logs.velocity_meas, meas_args{:});
plot(data.Time, data.("Vertical velocity"), true_args{:});
stairs(logs.Time, logs.velocity_est, est_args{:});
lgn = legend(Orientation = "horizontal");
lgn.Layout.Tile = "north";
xlabel("Time");
ylabel("Vertical velocity");
ysecondarylabel("m/s");

% sync for addition/subtraction
compare_data = synchronize(data, logs, ...
    "regular", "linear", SampleRate = input_rate)

compare_ax = nexttile; hold on; grid on;
stairs(compare_data.Time, compare_data.altitude_est - compare_data.("Altitude"));
ylabel("Estimation error");

nexttile; hold on; grid on;
stairs(compare_data.Time, compare_data.velocity_est - compare_data.("Vertical velocity"));
ylabel("Estimation error");
xlabel("Time");

stack_axes(layout);
xlim(data_ax, seconds([5 16]));
xlim(compare_ax, seconds([5 16]));
