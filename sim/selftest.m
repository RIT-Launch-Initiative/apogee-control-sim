clear;

rkt_file = pfullfile("data", "CRUD.ork");
doc = openrocket(rkt_file);

%% Get vehicle properties
% use OpenRocket's vehicle data calculators to get required parameters
GRAVITY = 9.807; % [m/s^2]
[~, MASS_DRY, INERTIA] = doc.massdata("BURNOUT");
PITCH_INERTIA = INERTIA(2);
[~, REF_AREA] = doc.refdims();
PLATE_AREA = 2 * 75e-3 * 20e-3; % [m^2] Total area - N petal * Width * Height
PLATE_CD = 1.2; % [-] Flat plate or so
CONTROL_BRAKE = false;

% drag lookup table using aerodata3()
n_drag_points = 100;
DRAG_DATA = table(linspace(0, 1.5, n_drag_points)', NaN(n_drag_points,1), ...
    VariableNames = ["MACH", "DRAG"]);
fc = doc.flight_condition(0);
for i_mach = 1:height(DRAG_DATA)
    fc.setMach(DRAG_DATA{i_mach, "MACH"});
    [~, DRAG_DATA{i_mach, "DRAG"}, ~, ~, ~] = doc.aerodata3(fc);
end

orsim = doc.sims(1);
opts = orsim.getOptions();
GROUND_LEVEL = opts.getLaunchAltitude();

%% Configure simulation
data = doc.simulate(orsim, outputs = "ALL", stop = "APOGEE");
burnout_state = data(eventfilter("BURNOUT"), :);

t_0 = seconds(burnout_state.Time);
t_f = seconds(data.Time(end)) + 5;
dt = 0.01;
position_init = burnout_state{1, ["Lateral distance", "Altitude"]}';
velocity_init = burnout_state{1, ["Lateral velocity", "Vertical velocity"]}';
const_brake = 0;
% ^ these need to be transposed to columns to fit what Simulink expects

%% Simulate
simout = sim("sim_2dof.slx");
outputs = extractTimetable(simout.yout);
logs = extractTimetable(simout.logsout);

%% Plot and compare
figure;
layout = tiledlayout("vertical");
layout.TileSpacing = "tight";

nexttile; hold on; grid on;
plot(data.Time, data.Altitude, DisplayName = "OpenRocket");
plot(outputs.Time, outputs.Altitude, DisplayName = "Simulink true");
plot(logs.Time, logs.altitude_measured, DisplayName = "Simulink measured");
ylabel("Altitude"); ysecondarylabel("m AGL");
legend(Location = "northoutside", Orientation = "horizontal");

nexttile; hold on; grid on;
plot(data.Time, data.("Drag force"), DisplayName = "OpenRocket");
plot(logs.Time, logs.drag_force, DisplayName = "Simulink true");
plot(logs.Time, -MASS_DRY * logs.accel_measured(:, 1), DisplayName = "Simulink measured");
ylabel("Drag force"); ysecondarylabel("N");

xlabel(layout, "Time");
