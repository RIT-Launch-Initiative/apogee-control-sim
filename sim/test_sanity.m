clear; close all;
%% Sanity check simulation against OpenRocket output

%% Flight data import
SL = 1401; % [m] sea level
openrocket = import_openrocket_csv("data\OMEN_OR_Output.csv");
openrocket.ASL = SL + openrocket.("Altitude");
openrocket.Properties.VariableUnits("ASL") = "m";

flight = timerange(eventfilter("LAUNCH"), eventfilter("APOGEE"), "closed");
openrocket = openrocket(flight, :);
burnout = openrocket(eventfilter("BURNOUT"), :);

% Simulation settings
% Assign every parameter to a single structure to use with struct2input() later
params.t_0 = seconds(burnout.Time);
params.dt = 0.01;
params.t_f = 40;

params.x_east_0 = burnout.("Lateral distance"); 
params.x_up_0 = burnout.("ASL");
params.v_east_0 = burnout.("Lateral velocity");
params.v_up_0 = burnout.("Vertical velocity");

% Vehicle settings
params.g = burnout.("Gravitational acceleration");
params.A_ref = (1e-2)^2 * (burnout.("Reference area")); % [m^2] reference area (from cm^2)
params.M_dry = burnout.Mass; % [kg]

% C_D lookup table from OR flight
C_D_lookup = openrocket(:, ["Mach number", "Drag coefficient"]);
C_D_lookup = sortrows(C_D_lookup, "Mach number", "ascend"); % Sort ascending by Mach number 
params.C_D_lookup = C_D_lookup;

params.C_D_brake = 1.2; % [-] approximately a flat plate
params.W_brake = 7.62 / 1e2; % [m] airbrake width - 3in (half dia.) 
params.N_brake = 2; % [-] how many airbrake fins there are
params.L_brake = 0; % [m] airbrake retracted

%% Run simulation cases
simin = struct2input("sim_2dof", params); % Put constants into simulation input
simout = sim(simin);
output = extractTimetable(simout.yout);

figure(name = "Output comparison");

nexttile;
% -SL to convert ASL to AGL 
plot(openrocket.Time, openrocket.ASL - SL, DisplayName = "OpenRocket"); 
plot(output.Time, output.x_up - SL, DisplayName = "Simulink");
legend;
ylabel("Altitude [m AGL]");
xlabel("Time");
