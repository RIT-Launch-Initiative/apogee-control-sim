clear;close all;
data = readtable("data.csv");

accel_cut_data = [data(2500:9400,:); data(15e3:19.8e3,:)];

figure(1);

tiledlayout(2,1,"TileSpacing","compact","Padding","compact");

nexttile;
% plot(data.timestamp__ms/1000,atmospalt(data.pressure__kpa*1000));
% plot(data.timestamp__ms/1000,data.pressure__kpa);
plot(data.pressure__kpa);

nexttile;
% plot(data.timestamp__ms/1000,data.accel_z__m_s2(2500:9400));
% plot(data.accel_z__m_s2(2500:9400));
% plot(data.accel_z__m_s2(15e3:19.8e3));
% plot(data.accel_z__m_s2);
plot(accel_cut_data.accel_z__m_s2);

std_accel = std(accel_cut_data.accel_z__m_s2) % [m/s^2]

std_pres = std(data.pressure__kpa * 1000) % [Pa]

load("3-Jun-2026-12.0.0-spaceport-midland-gfs.mat");

meters_per_pa = abs((airdata.HGT(11) - airdata.HGT(1)) / (airdata.PRES(11) - airdata.PRES(1))) % [m/Pa]

std_alt = (std(data.pressure__kpa * 1000) * meters_per_pa)^2 % [m^2]