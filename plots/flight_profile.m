clear;
project_globals;
flight_data = imports.primary_data;
drg_time = flight_data(eventfilter("DROGUE"), :).Time;
ascent_data = flight_data(timerange(seconds(-Inf), drg_time), :);


peak_velocity = 0.8 * 334; % [m/s] first time we can start extending
drag_fraction = 0.90; % [-] fraction we consider "almost all" of the drag

orsim = doc.sims(1);
simdata = doc.simulate(orsim, outputs = "ALL", stop = "APOGEE");
simdata = simdata(timerange(eventfilter("LAUNCHROD"), eventfilter("APOGEE")), :);

i_start = find(simdata.("Total velocity") >= peak_velocity, 1, "last");

drag_power = simdata.("Drag force") .* simdata.("Total velocity");
energy_removed = cumtrapz(seconds(simdata.Time), drag_power);
i_end = find((energy_removed - energy_removed(i_start)) <= ...
    drag_fraction * (energy_removed(end) - energy_removed(i_start)), 1, "last");

%% Plots
% fd_figure = figure(name = "Measured flight data");
% layout = tiledlayout("vertical");
%
% nexttile; grid on; hold on;
% plot(ascent_data, "Altitude");
% ylabel("Altitude");
% ysecondarylabel("m AGL");
%
% nexttile; grid on; hold on;
% plot(ascent_data, "Velocity")
% ylabel("Vertical velocity");
% ysecondarylabel("m/s");
%
% stack_axes(layout);
%
% export_at_size(fd_figure, "flight_data.pdf", [500 340]);

roi_figure = figure(name = "Time region of interest");
layout = tiledlayout("vertical");

tm_range = simdata.Time([i_start, i_end]);
alt_range = simdata.Altitude([i_start, i_end]);

nexttile; hold on; grid on;
xregion(tm_range);
plot(simdata.Time, simdata.("Total velocity"))
yline(peak_velocity, "--k", Label = "Mach 0.8");
ylabel("Velocity");
ysecondarylabel("m/s");

nexttile; hold on; grid on;
plot(simdata.Time, simdata.("Drag force"));
xregion(tm_range);
xline(tm_range(2), "--k", ...
sprintf("%d%% energy\nremoved", round(100*drag_fraction)), ...
LabelVerticalAlignment = "top", LabelOrientation = "horizontal");
ylabel("Drag force");
ysecondarylabel("N");

nexttile; hold on; grid on;
xregion(tm_range);
plot(simdata.Time, rad2deg(simdata.("Angle of attack")));
yline(1, "--k", Label = "1^\circ AOA", LabelHorizontalAlignment = "right");
ylabel("Angle of attack");
ysecondarylabel("deg");
% xlabel("Time");

nexttile; hold on; grid on;
xregion(tm_range);
plot(simdata.Time, simdata.("Altitude"));
yline(max(simdata.("Altitude")), "--k", sprintf("Apogee %.0f m", max(simdata.("Altitude"))), ...
    LabelVerticalAlignment = "bottom", LabelHorizontalAlignment = "right");
yline(alt_range, ":k", compose("%.0f m", alt_range), ...
    LabelHorizontalAlignment = "left");
xline(tm_range, ":k", string(tm_range), ...
    LabelVerticalAlignment = "bottom", LabelOrientation = "horizontal");
ylabel("Altitude");
ysecondarylabel("m AGL");


xlabel("Time");
stack_axes(layout);

fontsize(9, "points");
export_at_size(roi_figure, "roi.pdf", [600 600]);
return;
