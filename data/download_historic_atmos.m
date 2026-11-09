% For right now this just caches a bunch of arrays in our common airdata
% format that we've been using. Eventually it may be good to use xarray to
% store all the properties in an elegant row wise table that plays well
% with vectorized analysis like mean(column 1) instead of a for loop that
% has to read through each airdata table and grab something

% How many atmosphere models you download may drive the monte carlo cases
% for now, maybe later there is a good way to use mismatched sample sizes
% and keep reasonable statistical integrity

% Only run the sections you want since getting many takes a while

%% Setup
project_globals;

atmos_path = pfullfile("data", "cachemospheres");
% atmos_files = dir(fullfile(atmos_path, "*-Jun-202*.mat"));

sitename = "spaceport-midland";
site = launchsites(sitename);
site_tz = "America/Chicago";

model = "nam";
product = "conusnest.hiresf";

nominal_datetime = datetime(2026, 6, 16, 9, 00, 00, TimeZone = site_tz);

many_yrs = 2000 + (23:26);
many_months = 6;
many_days = 16:19;
many_hrs = 7 : 7+12; % Local Midland time
many_array = table2array(combinations(many_yrs, many_months, many_days, many_hrs, 0, 0));
many_datetimes = datetime(many_array, TimeZone = site_tz);

function data = sort_pressure_levels(data)
    data.layer = str2double(extract(data.layer, digitsPattern));
    data = sort(data, "layer", "descend");
end

%% Get nominal

ncep_object = ncep.analysis(model, product, nominal_datetime);

airdata_xarray = ncep_object.read_point(site.lat, site.lon, layer = digitsPattern + " mb", field = ["UGRD", "VGRD", "HGT", "TMP"]);
airdata_xarray = sort_pressure_levels(airdata_xarray);

PRES = airdata_xarray.layer .* 100;
airdata = [PRES double(airdata_xarray)];
airdata = array2table(airdata, "VariableNames", {'PRES','HGT','TMP','UGRD','VGRD'});

airs.airdata = airdata;
save(pfullfile("data", string(datetime(ncep_object.cycle, TimeZone=site_tz), "d-MMM-yyyy-HH.m.s") + "-" + sitename + "-" + model + ".mat"), "airdata");

fprintf("Finished 1/%d\n", height(many_datetimes) + 1);

pause(5);

%% Get many atmosphere models

many_airdata = cell(height(many_datetimes), 1);

for i_date = 1:height(many_datetimes)
    this_datetime = many_datetimes(i_date);

    ncep_object = ncep.analysis(model, product, this_datetime);

    airdata_xarray = ncep_object.read_point(site.lat, site.lon, layer = digitsPattern + " mb", field = ["UGRD", "VGRD", "HGT", "TMP"]);
    airdata_xarray = sort_pressure_levels(airdata_xarray);
    
    PRES = airdata_xarray.layer .* 100;
    airdata = [PRES double(airdata_xarray)];
    airdata = array2table(airdata, "VariableNames", {'PRES','HGT','TMP','UGRD','VGRD'});
    
    many_airdata{i_date} = airdata;
    save(fullfile(atmos_path, string(datetime(ncep_object.cycle, TimeZone=site_tz), "d-MMM-yyyy-HH.m.s") + "-" + sitename + "-" + model + ".mat"), "airdata");

    fprintf("Finished %d/%d\n", i_date + 1, height(many_datetimes) + 1);
    
    % Prevent rate limiting
    pause(5);
end

% Actually cache everything
airs.many_airdata = many_airdata;

%% Analyze data

% % files = dir("*-Jun-2024*.mat");
% files = dir(fullfile(atmos_path, "*-Jun-202*.mat"));
% % files = [dir("*-Jun-2025-08*.mat");dir("*-Jun-2025-14*.mat")];
% 
% num_files = length(files);
% 
% tiledlayout(4,1,"TileSpacing","compact","Padding","compact");
% % sgtitle("Big Weather Trying To Get Us Down 😠");
% 
% nexttile;
% for i = 1:num_files
%     filename = files(i).name;
%     dt = datetime(filename(1:18),"Format","d-MMM-yyyy-HH.m.s");
%     load(filename);
%     % atms.year = dt.Year;
%     plot(airdata.PRES/1000,airdata.HGT,"Color",[0.2 0.2 1 0.3]);hold on;
% end
% 
% xlim([67.5 100]);
% grid on;
% yline([3048+180],"k--");
% xline([70],"--k","LineWidth",1);
% text(75,3550,"Apogee = 3228 m");
% ylabel("Altitude (m)");
% yticks(0:1000:4000);
% title("Pressure Altitude of Each Atmosphere Model");
% set(gca,"xdir","reverse");
% 
% nexttile;
% airdatas = [];
% for i = 1:num_files
%     filename = files(i).name;
%     dt = datetime(filename(1:18),"Format","d-MMM-yyyy-HH.m.s");
%     load(filename);
%     airdatas(:,i) = airdata.HGT;
% end
% my_std = std(airdatas,0,2);
% plot(airdata.PRES/1000,my_std,"LineWidth",1);hold on;
% 
% xlim([67.5 100]);
% grid on;
% xline([70],"--k","LineWidth",1);
% ylabel("Altitude (m)");
% ylim([0 max(my_std)]);
% set(gca,"xdir","reverse");
% title("68% of PA's Are Closer Than This Amount To The Mean Model's PA");
% 
% nexttile;
% my_range = range(airdatas,2);
% plot(airdata.PRES/1000,my_range,"LineWidth",1);hold on;
% xlim([67.5 100]);
% grid on;
% xline([70],"--k","LineWidth",1);
% % xlabel("Pressure (kPa)");
% ylabel("Altitude (m)");
% ylim([0 max(my_range)]);
% set(gca,"xdir","reverse");
% title("Worst Altitude Range Between Models = " + string(round(max(my_range(1:14)),0)) + " m");
% 
% nexttile;
% windmag = [];
% for i = 1:num_files
%     filename = files(i).name;
%     dt = datetime(filename(1:18),"Format","d-MMM-yyyy-HH.m.s");
%     load(filename);
%     windmag(:,i) = vecnorm([airdata.UGRD airdata.VGRD],2,2);
% end
% windmagavg = mean(windmag,2);
% windmagstd = std(windmag,0,2);
% plot(airdata.PRES/1000,windmagavg,"LineWidth",1);hold on;
% plot(airdata.PRES/1000,windmagavg+windmagstd,"--","LineWidth",1);
% plot(airdata.PRES/1000,windmagavg-windmagstd,"--","LineWidth",1);
% xlim([67.5 100]);
% grid on;
% xline([70],"--k","LineWidth",1);
% xlabel("Pressure (kPa)");
% ylabel("Velocity (m/s)");
% ylim([0 20]);
% set(gca,"xdir","reverse");
% title("Wind Magnitude");
% 
% start_brake = interp1(mean(airdatas,2),airdata.PRES,alt_start);
% nexttile(1);
% fill([[start_brake start_brake]/1000 70 70],[0 4000 4000 0],"g","FaceAlpha",0.1,"EdgeColor","none");
% text(mean([start_brake/1000 70+3]),2000,"Airbrakes","Color",[0 0.6 0]);
% nexttile(2);
% fill([[start_brake start_brake]/1000 70 70],[0 max(my_std) max(my_std) 0],"g","FaceAlpha",0.1,"EdgeColor","none");
% text([100-0.1 start_brake/1000 70-0.1],[my_std(1) interp1(1:height(my_std),my_std,interp1(airdata.PRES,1:height(airdata),start_brake)) my_std(13)],string(round([my_std(1) interp1(1:height(my_std),my_std,interp1(airdata.PRES,1:height(airdata),start_brake)) my_std(13)],0)),"Color","r","FontWeight","bold","FontSize",12);
% nexttile(3);
% fill([[start_brake start_brake]/1000 70 70],[0 max(my_range) max(my_range) 0],"g","FaceAlpha",0.1,"EdgeColor","none");
% text([100-0.1 start_brake/1000 70-0.1],[my_range(1) interp1(1:height(my_range),my_range,interp1(airdata.PRES,1:height(airdata),start_brake)) my_range(13)],string(round([my_range(1) interp1(1:height(my_range),my_range,interp1(airdata.PRES,1:height(airdata),start_brake)) my_range(13)],0)),"Color","r","FontWeight","bold","FontSize",12);
% nexttile(4);
% fill([[start_brake start_brake]/1000 70 70],[0 20 20 0],"g","FaceAlpha",0.1,"EdgeColor","none");
% 
% figure(51);
% windavgu = mean(airdata.UGRD);
% windavgv = mean(airdata.VGRD);
% 
% for i = 1:height(airdata)
%     quiver(0,0,airdata.UGRD(i),airdata.VGRD(i));hold on;
% end
% quiver(0,0,windavgu,windavgv,"LineWidth",10);