clear;
project_globals;
flight_data = imports.primary_data;
drg_time = flight_data(eventfilter("DROGUE"), :).Time;
ascent_data = flight_data(timerange(seconds(-Inf), drg_time), :);


peak_velocity = 0.8 * 334; % [m/s] first time we can start extending
drag_fraction = 0.95; % [-] fraction we consider "almost all" of the drag

orsim = doc.sims(1);
simdata = doc.simulate(orsim, outputs = "ALL", stop = "APOGEE");
simdata = simdata(timerange(eventfilter("LAUNCHROD"), eventfilter("APOGEE")), :);
i_start = find(simdata.("Total velocity") >= peak_velocity, 1, "last");
drag_power = simdata.("Drag force") .* simdata.("Total velocity");
energy_removed = cumtrapz(seconds(simdata.Time), drag_power);
i_end = find((energy_removed - energy_removed(i_start)) <= ...
    drag_fraction * (energy_removed(end) - energy_removed(i_start)), 1, "last");


%% Plots
fd_figure = figure(name = "Measured flight data");
layout = tiledlayout("vertical");

nexttile; grid on; hold on;
plot(ascent_data, "Altitude");
ylabel("Altitude");
ysecondarylabel("m AGL");

nexttile; grid on; hold on;
plot(ascent_data, "Velocity")
ylabel("Vertical velocity");
ysecondarylabel("m/s");

stack_axes(layout);

export_at_size(fd_figure, "flight_data.pdf", [500 340]);

roi_figure = figure(name = "Time region of interest");
layout = tiledlayout("vertical");


nexttile; hold on; grid on;
plot(simdata.Time, simdata.("Total velocity"))
xregion(simdata.Time([i_start i_end]));
yline(peak_velocity, "--k", Label = "Mach 0.8");
ylabel("Velocity");
ysecondarylabel("m/s")


nexttile; hold on; grid on;
plot(simdata.Time, simdata.("Drag force"));
xregion(simdata.Time([i_start i_end]));
xline(simdata.Time(i_end), "--k", Label = sprintf("%d%% energy\nremoved", round(100*drag_fraction)))
ylabel("Drag force");
ysecondarylabel("N");

nexttile; hold on; grid on;
plot(simdata.Time, simdata.("Altitude"));
yregion(simdata.Altitude([i_start i_end]));
ylabel("Altitude");
ysecondarylabel("m AGL");
xlabel("Time");

stack_axes(layout)

export_at_size(roi_figure, "roi.pdf", [600 400]);

simp_figure = figure(name = "Permitted simplifications");
layout = tiledlayout("vertical");
regiondata = simdata(i_start:i_end, :);

nexttile; grid on; hold on;
plot(regiondata.Time, regiondata.("Vertical velocity"), "-", DisplayName = "Vertical");
plot(regiondata.Time, regiondata.("Total velocity"), "--", DisplayName = "Total");
ylabel("Velocity");
ysecondarylabel("m/s");
legend(Location = "northeast");

nexttile; grid on; hold on;
plot(regiondata.Time, rad2deg(regiondata.("Angle of attack")));
yline(1, "--k", Label = "1^\circ AOA", LabelHorizontalAlignment = "center");
ylabel("Angle of attack");
ysecondarylabel("deg");
xlabel("Time");
stack_axes(layout);

export_at_size(simp_figure, "simplifications.pdf", [600 300]);
