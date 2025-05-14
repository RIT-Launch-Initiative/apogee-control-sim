clear;
datasets = matfile(pfullfile("data", "imports.mat"), Writable = false);

grim_data = datasets.grim_data;
f_s = grim_data.Properties.SampleRate;
[high_num, high_den] = butter(4, 2*20/f_s, "low");
[lo_num, lo_den] = butter(4, 2/f_s, "low");
diff_num = [1 -1];
diff_den = [1/f_s 0];

grim_data.baro_filt = filter(high_num, high_den, grim_data.baro);
grim_data.alt = pressalt("m", grim_data.baro, "kPa");
grim_data.alt_filt = pressalt("m", grim_data.baro_filt, "kPa");
grim_data.vel = filter(diff_num, diff_den, grim_data.alt);
grim_data.vel_filt = filter(lo_num, lo_den, grim_data.vel);

figure;
layout = tiledlayout("vertical");
layout.TileSpacing = "compact";

nexttile; hold on; grid on;
plot(grim_data.Time, grim_data.alt, DisplayName = "Raw");
plot(grim_data.Time, grim_data.alt_filt, DisplayName = "Filtered");
ylabel("Altitude"); ysecondarylabel("m ASL");
ylim([1000 5100]);

nexttile; hold on; grid on;
plot(grim_data.Time, grim_data.vel, DisplayName = "Raw");
plot(grim_data.Time, grim_data.vel_filt, DisplayName = "Filtered");
ylabel("Vertical velocity"); ysecondarylabel("m/s");
ylim([-100 400]);

xlabel(layout, "Time");
