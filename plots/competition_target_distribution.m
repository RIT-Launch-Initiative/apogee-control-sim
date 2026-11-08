atmos_path = pfullfile("data", "atmosphere");

atmos_files = dir(fullfile(atmos_path, "*-Jun-202*.mat"));

num_files = length(atmos_files);

% Remove duplicate atmosphere models
idx_to_remove = false([num_files 1]);
last_airdata = NaN;
for i_file = 1:num_files
    filename = atmos_files(i_file).name;
    load(fullfile(atmos_files(i_file).folder, atmos_files(i_file).name));
    if isequal(airdata, last_airdata)
        idx_to_remove(i_file) = true;
    end
    last_airdata = airdata;
end
atmos_files(idx_to_remove) = [];
num_files = length(atmos_files);

figure(name = "Pressure altitudes");
tiledlayout(1, 1, TileSpacing="compact", Padding="compact");
nexttile;

targets = NaN([num_files 1]);
for i_file = 1:num_files
    filename = atmos_files(i_file).name;
    dt = datetime(filename(1:18),"Format","d-MMM-yyyy-HH.m.s");
    load(fullfile(atmos_files(i_file).folder, atmos_files(i_file).name));

    generate_target;

    targets(i_file) = apogee_target;

    switch double(string(filename(8:11)))
        case 2023
            color = [0 1 0];
        case 2024
            color = [0 0 1];
        case 2025
            color = [1 0 0];
    end

    plot(airdata.PRES, airdata.HGT, "o", Color=[color 0.3], LineWidth=2); hold on;
end

xlim([65e3 100e3]);
xline(70e3);
xlabel("Pressure (Pa)");
ylabel("Altitude ASL (m)");
title("Apogee target distribution (range = " + string(round(range(targets), 0)) + " m)");
grid on;

figure(name = "Apogee target distribution");
tiledlayout(1, 1, TileSpacing="compact", Padding="compact");
nexttile;

histogram(targets, num_files);

xlabel("Target apogee AGL (m)");
ylabel("Count (-)");
text(min(targets), 0, string(round(min(targets),0)), VerticalAlignment="bottom", HorizontalAlignment="right", Color="k", FontWeight="bold", FontSize=18);
text(max(targets), 0, string(round(max(targets),0)), VerticalAlignment="bottom", HorizontalAlignment="left",  Color="k", FontWeight="bold", FontSize=18);
title("Apogee target distribution (range = " + string(round(range(targets), 0)) + " m)");
grid on;