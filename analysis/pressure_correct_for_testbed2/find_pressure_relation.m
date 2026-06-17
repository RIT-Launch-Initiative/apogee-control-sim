%% Setup
clear;close all;clc

testbed1_dir = pfullfile("..","flight-data","2026","Testbed","Testbed1","flight","controls_module");

data.raw.cm = readtable(fullfile(testbed1_dir,"data.csv"));
data.raw.br = readtable(fullfile(testbed1_dir,"TheBlueRaden! LR_10-12-2025_16_03_56_4.csv"));

data.cm = data.raw.cm;
data.cm.time = (data.cm.timestamp__ms - data.cm.timestamp__ms(1)) / 1000;

data.br = data.raw.br;
data.br.time = seconds(data.br.Time - data.br.Time(1));
data.br.pressure_kpa = data.br.Baro_Press__atm_ .* 101.325;

br_diff = mean(data.br.pressure_kpa(3400:end)) - mean(data.cm.pressure__kpa(6650:end));
% br_diff = 0;
data.br.pressure_kpa = data.br.pressure_kpa - br_diff;
% data.br.time = data.br.time - 1.48;
data.br.time = data.br.time - 1.52;
data.br.velocity = data.br.Velocity_Up / 3.281;

data.cm.pressure_pa = data.cm.pressure__kpa * 1000;
data.br.pressure_pa = data.br.pressure_kpa * 1000;

data.br = data.br(77:end,:);

%% Splicing

data.cut.cm = data.cm;

data.cut.cm.pressure_pa(341:427) = linspace(96131, 94724, 427 - 341 + 1);

data.cut.cm.pressure_pa(473:560) = linspace(94022, 92808, 560 - 473 + 1);

data.cut.cm.pressure_pa(610:699) = linspace(92186, 91174, 699 - 610 + 1);

data.cut.cm.pressure_pa(750:835) = linspace(90655, 89859, 835 - 750 + 1);

data.cut.cm.pressure_pa(887:969) = linspace(89440, 88837, 969 - 887 + 1);

data.cut.cm.pressure_pa(1024:1103) = linspace(88482, 88041, 1103 - 1024 + 1);

data.cut.cm.pressure_pa(1161:1237) = linspace(87762, 87453, 1237 - 1161 + 1);

plot(data.cut.cm.pressure_pa);
xlim([0 1573]);

%% Plot against cut

time_range = [0 16];

tiledlayout(3,1,"TileSpacing","compact","Padding","compact");

nexttile;
plot(data.br.time, data.br.velocity);
grid on;
xlim(time_range);
xlabel("Time (s)");ylabel("Velocity (m/s)");

nexttile;
yyaxis left;
plot(data.cm.time, data.cm.pressure_pa);
hold on;
plot(data.cut.cm.time, data.cut.cm.pressure_pa);
grid on;
xlim(time_range);
xlabel("Time (s)");ylabel("Pressure (Pa)");
yyaxis right;
plot(data.cm.time, data.cm.effort);
ylabel("Effort (-)")
axis padded;
xlim(time_range);

nexttile;
error = data.cm.pressure_pa - data.cut.cm.pressure_pa;
error(error == 0) = NaN;
plot(data.cm.time, error);
grid on;
xlim(time_range);
xlabel("Time (s)");ylabel("Pressure (Pa)");

figure;
error_on_br_time = interp1(data.cm.time, error, data.br.time);

error_on_br_time1 = error_on_br_time;
error_on_br_time1(1:185) = NaN;
error_on_br_time1(203:247) = NaN;
error_on_br_time1(273:316) = NaN;
error_on_br_time1(339:384) = NaN;
error_on_br_time1(409:455) = NaN;
error_on_br_time1(476:522) = NaN;
error_on_br_time1(541:589) = NaN;
error_on_br_time1(610:end) = NaN;

mask = ~isnan(error_on_br_time1);

[~,~,~,rhos,~,~] = atmosisa(data.br.Baro_Altitude_ASL__feet_ ./ 3.281);
q = 0.5 .* rhos .* data.br.velocity .^ 2;
% q = data.br.velocity;
plot(q, error_on_br_time);
hold on;
plot(q, error_on_br_time1,"m");
hold on;
% plot([0 13e3], [-150 -2200],"--r");
% plot([0 13e3], [0 -2800],"--r");
grid on;

x1 = q(mask);
y1 = error_on_br_time1(mask)/1000;

p = polyfit(q(mask), error_on_br_time(mask), 1);

% q = linspace(0, 30e3, 100);
plot(q, polyval(p,q));

xlabel("Vertical Velocity (m/s)");ylabel("Pressure Correction (Pa)");

% a = -0.0601;
% b = -4.0067;

a = -6.0141e-05;
b = -0.0040;

% q = linspace(0, 500, 100);
% plot(q, polyval([a b 0],q).*1000);

title("Correction as a function of dynamic pressure");

%% Plot against BR
% 
% time_range = [0 16];
% 
% tiledlayout(3,1,"TileSpacing","compact","Padding","compact");
% 
% nexttile;
% plot(data.br.time, data.br.velocity);
% grid on;
% xlim(time_range);
% xlabel("Time (s)");ylabel("Velocity (m/s)");
% 
% nexttile;
% plot(data.cm.time, data.cm.pressure_pa);
% hold on;
% plot(data.br.time, data.br.pressure_pa);
% grid on;
% xlim(time_range);
% xlabel("Time (s)");ylabel("Pressure (Pa)");
% 
% nexttile;
% cm_on_br_time = interp1(data.cm.time, data.cm.pressure_pa, data.br.time);
% error = cm_on_br_time - data.br.pressure_pa;
% plot(data.br.time, error);
% grid on;
% xlim(time_range);
% xlabel("Time (s)");ylabel("Pressure (Pa)");
% 
% figure;
% [~,~,~,rhos,~,~] = atmosisa(data.br.Baro_Altitude_ASL__feet_ ./ 3.281);
% plot(0.5 .* rhos(1:875) .* data.br.velocity(1:875) .^ 2,error(1:875));
% hold on;
% % plot([0 13e3], [-150 -2200],"--r");
% plot([0 13e3], [0 -2800],"--r");
% grid on;