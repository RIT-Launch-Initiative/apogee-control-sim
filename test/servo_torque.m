%% CALCS For Servo
clear
close all
clc

%% Constants
m1 = 0.064;         % [kg] Mass of the leaflet
m2 = 0.0033;        % [kg] Mass of the link
m3 = 0.0031;        % [kg] Mass of the middle link
m4 = 0.0792;        % [kg] Mass of the carriage
m = m1 + m2 + m3;   % [kg] Total mass

d1 = 0.0381;    % [m] Link length
d2 = 0.04318/2; % [m] Middle link length

gap = 0.02132;   % [m] Initial gap between leaflet and servo in the triangle
dt = 0.5;         % [s] Min time to reach full extension

v = 275;        % [m/s] Velocity
rho = 1.2;      % [kg/m^3] Density
Cd = 1.2;       % Plate drag coefficient
width = 0.09525; % [m] Plate width

g = 9.81;       % [m/s^2] Force of gravity
G = g * 1;      % How many Gs are experienced after boost
mu = 0.05;       % Rail friction (worst case)
k = 300;         % [N/m] Spring constant

theta1 = 45:135; % [deg] range of motion
FoS = 3; % Factor of safety

%% Calculations
theta2 = asind((d2/d1) .* sind(theta1));
theta3 = 180 - theta1 - theta2;
phi = theta3 - 90;
dx = d1 * (sind(theta3)./sind(theta1)) - gap; % [m] Extension distance
A = dx * width;


Fd = 0.5 * rho * Cd * A * v^2; % [N] Force of drag
Fn = Fd + m * G; % [N] Normal Force
fric = mu * Fn; % [N] Friction force (Static friction as that is what needs to be overcome)
Fs = k * dx;

a = 2 * dx / dt ^ 2; % [m/s^2] Min acceleration needed from rest

Fa = fric + Fs + m * a; % [N] Force needed to move airbrakes

T = (Fa * d1) ./ (cosd(phi) .* cosd(theta2)); % [Nm] Torque needed to apply that force
Torque = FoS * T * 10.1971621297792 * 2; % [kg cm] Final torque needed for both leaflets


%% Plotting
figure
hold on
yline(25)
plot(theta1, Torque)
xlabel('Servo Angle [deg]')
ylabel('Torque [kg-cm]')
legned('Current Servo Torque', 'Projected Torque Needed')




