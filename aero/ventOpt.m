%% Airbrakes Vent Hole Size Optimization
% Originally created by Juno Afko for IREC 2026 Testbed
% Modified by Zoey Sugerman-Brozan for IREC 2026 Airbrakes
%% Problem Statement and Assumptions
% The Kalman filter-Quantile LUT control approach used by the IREC 2026
% airbrakes controller relies on accurate readings of barometric pressure.
% Thus, it is imperative to size the avionics vent holes and screw switch
% holes appropriately to minimize error in those pressure measurements as
% much as possible. This script will simulate airflow into and out of the
% avionics section of the airbrakes bay to enable optimal sizing of the
% venting and screw switch holes.
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
% air to outside. Pressure losses through vent holes and screw switch holes
% are assumed to be equal to the dynamic pressure.

%% Setup
clc
clear;
close all;
% Run a test OR sim of either IREC 2026 or TB-1
IRECPath = "..\data\IREC-2026-N3800.ork"; 
if ~isfile(IRECPath)
    error("Error: not on path", IRECPath);
end
TBPath = "..\data\TB-1.ork"; 
if ~isfile(TBPath)
    error("Error: not on path", TBPath);
end
rocket = openrocket(TBPath);
sim = rocket.sims("15mph_URRG");
openrocket.simulate(sim);
% Get data and trim
simData = openrocket.get_data(sim);
data_range = timerange(eventfilter("LAUNCH"), eventfilter("MAIN"), "openleft");
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
function [mdot, Hdot] = flowCalc(V1, V2, V3, A1, A2, C_L)
    rho1 = min(V1.rho, V3.rho);
    rho2 = min(V2.rho, V3.rho);
    v1 = sign(V1.P - V3.P)*sqrt(2*abs(V1.P-V3.P)/(rho1*C_L));
    v2 = sign(V3.P - V2.P)*sqrt(2*abs(V3.P-V2.P)/(rho2*C_L));
    mdot(1) = v1*A1*rho1;
    mdot(2) = v2*A2*rho2;
    if v1 >= 0
        Hdot(1) = mdot(1)*V1.h;
    else
        Hdot(1) = mdot(1)*V3.h;
    end
    if v2 >= 0
        Hdot(2) = mdot(2)*V3.h;
    else
        Hdot(2) = mdot(2)*V2.h;
    end
end
function [mdot, Hdot] = ventCalc(V1, air, Avent)
    rho = min(air.rho, V1.rho);
    v = sign(V1.P-air.P)*sqrt(2*(V1.P - air.P)/rho);
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
function plotPuck(time, simTime, pressures, Verr, data, titleStr)
    subplot(2, 1, 1);
    plot(time, data.("Air pressure")*10^-3, "b");
    hold on;
    plot(simTime, pressures(:,1), "r");
    plot(simTime, pressures(:,2), "m");
    plot(simTime, pressures(:,3), "k");
    legend("Ambient pressure", "CV 1", "CV 2", "CV 3");
    hold off;
    xlim([0, simTime(end)]);
    ylabel("Pressure [kPa]");
    title(titleStr);
    subplot(2, 1, 2)
    plot(simTime, Verr)
    xlim([0, simTime(end)]);
    xlabel("Time [s]");
    ylabel("P1 error [%]");
end
function plotConv(time, simTime, pressures, Verr, data, titleStr)
    subplot(2, 1, 1);
    plot(time, data.("Air pressure")*10^-3, "b");
    hold on;
    plot(simTime, pressures, "r");
    legend("Ambient pressure", "Avbay pressure");
    hold off;
    xlim([0, simTime(end)]);
    ylabel("Pressure [kPa]");
    title(titleStr);
    subplot(2, 1, 2)
    plot(simTime, Verr)
    xlim([0, simTime(end)]);
    xlabel("Time [s]");
    ylabel("P1 error [%]");
end