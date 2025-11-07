%% Airbrakes Vent Hole Size Optimization
% Originally created by Juno Afko for TB-1
% Modified by Zoey Sugerman-Brozan for IREC 2026 Airbrakes
%% Problem Statement and Assumptions
% The Kalman filter-Quantile LUT control approach used by the IREC 2026
% airbrakes controller relies on accurate readings of barometric pressure.
% Thus, it is imperative to size the avionics vent hole appropriately to
% minimize error in those pressure measurements as much as possible. This
% script will simulate airflow into and out of the avionics section of the 
% airbrakes bay to enable optimal sizing of the venting hole.
%
% The airbrakes bay is split into two sections: a lower mechanical subbay
% containing the leaflets, servo, and extentsion mechanism, and an upper
% electrical subbay containing the flight computer, batteries, screw
% switches, and any other required avionics. These volumes are separated by
% a bulkhead, which mounts to standoffs connected to the lower bulkhead
% upon which the mechanical components are mounted. The aim of this
% electronics bulkhead is twofold: first, to ensure secure mounting for
% the avionics, and secondly, to separate the airbrakes bay into two
% pressure zones. Because the airbrakes extend out of slots in the body
% tube, they cause pressure effects in the mechanical bay that are
% undesirable for the avionics and would introduce errors into the
% barometric pressure readings. Thus, the electronics bulkhead separates
% the zones, preventing the extension of the airbrakes from interfering
% with the pressure readings and making the electronics section of the bay
% effectively similar to a conventional avionics bay.
%
% The electronics bay is treated as a single, isolated volume which vents
% air to outside. Pressure losses through the vent hole is assumed to be
% equal to the dynamic pressure.

%% Setup
clc
clear;
close all;
% Run a test OR sim of either IREC 2026 or TB-1
IRECPath = "..\data\IREC-2026-N3800.ork"; 
if ~isfile(IRECPath)
    error("Error: %s not on path", IRECPath);
end
TBPath = "..\data\TB-1.ork"; 
if ~isfile(TBPath)
    error("Error: %s not on path", TBPath);
end
rocket = openrocket(IRECPath);    % use either TB-1 or IREC
sim = rocket.sims("15mph-Midland");% name changes for either TB-1 or IREC
openrocket.simulate(sim);
% Get data and trim
simData = openrocket.get_data(sim);
data_range = timerange(eventfilter("LAUNCH"), eventfilter("APOGEE"), "openleft");
data = simData(data_range, [("Air pressure"), ("Air temperature")]);
time = round(seconds(data.Time), 3);
Pdata = griddedInterpolant(time, data.("Air pressure")*10^-3); % interpolants for sim loop
Tdata = griddedInterpolant(time, data.("Air temperature"));
% Define airflow sim parameters
% initialize ambient conditions
air.R = 0.278;
air.P = data.("Air pressure")(1)*10^-3;
air.T = data.("Air temperature")(1);
air.rho = air.P/(air.R*air.T);
air.Cp = 1.005;
air.h = air.T*air.Cp;
% Control volume
elecBay = initControlVolume(1.263*10^-3, air);
% Other parameters
holeSizes = ["1/8", "5/32", "3/16", "7/32", "1/4"]; % in strings for plot legend
ventHoleDiams = arrayfun(@(s) str2num(s), holeSizes); % in inches
ventHoleDiams = ventHoleDiams*0.0254;   % convert to meters
Avent = pi/4 * ventHoleDiams.^2;
Avent = [Avent, 2*Avent];
holeSizes = [holeSizes, strcat("2x ", holeSizes)];
% set timer parameters
t_end = time(end);
dt = 5*10^-3;

%% Simulate the electronics bay
% Overall timer and data collection
allSimTime = [];
allPressure = [];
allVerr = [];

% for each vent hole size
for i=1:length(Avent)
    % setup timer and data collection
    t = 0;
    simTime = [];
    pressure = [];
    Verr = [];

    thisElecBay = elecBay;  % create a control volume just for this iteration

    % iterate
    while (t <= t_end)
        % Current hole size under consideration
        holeArea = Avent(i);

        % Update ambient conditions
        air.P = Pdata(t);
        air.T = Tdata(t);
        air.rho = air.P/(air.R*air.T);
        % Vent hole flows
        [mdot, Hdot] = ventCalc(thisElecBay, air, holeArea);
        % Iterate mass and enthalpy
        dM = -mdot*dt;
        dH = -Hdot*dt;
        thisElecBay = updateVolume(thisElecBay, dM, dH, air);
        pressure = [pressure; thisElecBay.P];
        Verr = [Verr, 100*(thisElecBay.P-air.P)/air.P];
        % Iterate timer
        simTime = [simTime; t];
        disp(t);
        t = t + dt;
    end

    % add to overall arrays
    allSimTime = [allSimTime, simTime];
    allPressure = [allPressure, pressure];
    allVerr = [allVerr; Verr];
end
% plot results
figure();
plotPress(time, allSimTime, allPressure, allVerr, data, "Airbrakes Electronics Bay", holeSizes);

%% Functions
function controlVolume = initControlVolume(volume, air)
    controlVolume.V = volume; % it literally says what it is im not gonna tell u
    controlVolume.P = air.P; % air pressure
    controlVolume.T = air.T; % air temperature
    controlVolume.rho = air.rho; % air density
    controlVolume.M = volume*air.rho; % total air mass
    controlVolume.H = air.T*air.Cp*controlVolume.M; % total enthalpy
    controlVolume.h = controlVolume.H/controlVolume.M; % specific enthalpy
end
function [mdot, Hdot] = ventCalc(V1, air, Avent)
    rho = min(air.rho, V1.rho);
    v = sign(V1.P-air.P)*sqrt(2*abs(V1.P - air.P)/rho);
    mdot = v*rho*Avent;
    if v >= 0
        Hdot = mdot*V1.h;
    else
        Hdot = mdot*air.h;
    end
end

function Vol = updateVolume(Vol, dM, dH, air)
    Vol.M = Vol.M + dM;
    Vol.H = Vol.H + dH;
    Vol.h = Vol.H/Vol.M;
    Vol.T = Vol.h/air.Cp;
    Vol.rho = Vol.M/Vol.V;
    Vol.P = Vol.T*air.R*Vol.rho;
end
function plotPress(time, simTime, pressures, Verr, data, titleStr, holeStrs)
    colors = [orderedcolors("gem");orderedcolors("meadow")];
    tcl = tiledlayout(2,1, 'TileSpacing', 'compact');
    title(tcl, titleStr);
    nexttile
    plot(time, data.("Air pressure")*10^-3, "k","LineWidth",1.5);
    hold on;
    for i=1:size(simTime,2)
        plot(simTime(:,i), pressures(:,i),"Color",colors(i,:));
    end
    hold off;
    xlim([0, simTime(end)]);
    ylabel("Pressure [kPa]");
    nexttile
    hold on
    for i=1:size(simTime,2)
        plot(simTime(:,i), Verr(i,:),"Color",colors(i,:));
    end
    hold off
    xlim([0, simTime(end)]);
    xlabel("Time [s]");
    ylabel("P1 error [%]");
    lg = legend(nexttile(1), ...
        ["Ambient pressure", strcat(holeStrs, "'' vent")], ...
        "Location","eastoutside");
    lg.Layout.Tile = "east";
end