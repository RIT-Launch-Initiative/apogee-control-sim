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


% tiledlayout(4,1,"TileSpacing","compact","Padding","compact");
% sgtitle("sd");

% nexttile;
% for i = 1:num_files
%     filename = atmos_files(i).name;
%     dt = datetime(filename(1:18),"Format","d-MMM-yyyy-HH.m.s");
%     load(filename);
%     % atms.year = dt.Year;
%     plot(airdata.PRES/1000,airdata.HGT,"Color",[0.2 0.2 1 0.3]);hold on;
% end

targets = NaN([num_files 1]);

figure(1);
clf;
tiledlayout(1, 1, TileSpacing="compact", Padding="compact");
nexttile;

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

grid on;

figure(2);
clf;

tiledlayout(1, 1, TileSpacing="compact", Padding="compact");

nexttile;
histogram(targets, num_files);

xlabel("Geometric apogee target (m)");
ylabel("Count (-)");

text(min(targets), 0, string(round(min(targets),0)), VerticalAlignment="bottom", HorizontalAlignment="right", Color="k", FontWeight="bold", FontSize=18);
text(max(targets), 0, string(round(max(targets),0)), VerticalAlignment="bottom", HorizontalAlignment="left",  Color="k", FontWeight="bold", FontSize=18);

title("Midland apogee target distribution (range = " + string(round(range(targets), 0)) + " m)");

grid on;

% figure(1);