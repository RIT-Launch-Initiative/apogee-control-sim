%% Setup

sitename = "spaceport-midland";
site = launchsites(sitename);

model = "nam";
product = "conusnest.hiresf";

function data = sort_pressure_levels(data)
    data.layer = str2double(extract(data.layer, digitsPattern));
    data = sort(data, "layer", "descend");
end

%% Get data at analysis times
clear;

sitename = "spaceport-midland";
site = launchsites(sitename);

model = "nam";
product = "conusnest.hiresf";

% q_month = 6;
% q_day = 17;
% qtime1 = datetime(2025, q_month, q_day, 12, 00, 00, TimeZone = "America/New_York");

q_years = [2024];
q_days = 17:20;
q_hours = [2 8 14];
q_length = length(q_years)*length(q_days)*length(q_hours);

i = 1;
for q_year = q_years
    for q_day = q_days
        for q_hour = q_hours
            qtime = datetime(q_year, 6, q_day, q_hour, 00, 00, TimeZone = "America/New_York");

            ncep_object = ncep.analysis(model, product, qtime);

            airdata_xarray = ncep_object.read_point(site.lat, site.lon, layer = digitsPattern + " mb", field = ["UGRD", "VGRD", "HGT", "TMP"]);

            airdata_xarray = sort_pressure_levels(airdata_xarray);

            PRES = airdata_xarray.layer .* 100;
            airdata = [PRES double(airdata_xarray)];
            airdata = array2table(airdata, "VariableNames", {'PRES','HGT','TMP','UGRD','VGRD'});

            save(string(qtime, "d-MMM-yyyy-HH.m.s") + "-" + sitename + "-" + model + ".mat", "airdata");

            fprintf("Finished %d/%d\n",i,q_length);
            i = i + 1;
        end
    end
end

%% Get data at forecasted points in between analysis
% clear;

q_years = [2025 2024];
q_days = 18:20;
q_hours = [2 8 14];
q_length = length(q_years)*length(q_days)*length(q_hours);

i = 1;
for q_year = q_years
    for q_day = q_days
        for q_hour = q_hours
            qtime = datetime(q_year, 6, q_day, q_hour, 00, 00, TimeZone = "America/New_York");

            ftime = qtime + [hours(1) hours(5)]; % In between analysis points
            % ftime = qtime + hours(1); % Test point
            ncep_object = ncep.forecast(model, product, ftime, qtime);

            airdata_xarray = ncep_object.read_point(site.lat, site.lon, layer = digitsPattern + " mb", field = ["UGRD", "VGRD", "HGT", "TMP"]);

            airdata_xarray = sort_pressure_levels(airdata_xarray);

            for j = 1:size(airdata_xarray,1)
                PRES = airdata_xarray(j,:,:).layer .* 100;
                airdata = [PRES double(airdata_xarray(j,:,:))];
                airdata = array2table(airdata, "VariableNames", {'PRES','HGT','TMP','UGRD','VGRD'});
    
                save(string(airdata_xarray(j,:,:).time, "d-MMM'F'-yyyy-HH.m.s") + "-" + sitename + "-" + model + ".mat", "airdata");
    
                fprintf("Finished %d/%d\n",i,q_length);
                i = i + 1;
            end

            pause(5);
        end
    end
end





%% Analyze data
% clear;close all;

project_globals;

figure(50);

hold off;

% files = dir("*-Jun-2024*.mat");
files = dir("*-Jun-202*.mat");
% files = [dir("*-Jun-2025-08*.mat");dir("*-Jun-2025-14*.mat")];

num_files = length(files);

tiledlayout(4,1,"TileSpacing","compact","Padding","compact");
% sgtitle("Big Weather Trying To Get Us Down 😠");

nexttile;
for i = 1:num_files
    filename = files(i).name;
    dt = datetime(filename(1:18),"Format","d-MMM-yyyy-HH.m.s");
    load(filename);
    % atms.year = dt.Year;
    plot(airdata.PRES/1000,airdata.HGT,"Color",[0.2 0.2 1 0.3]);hold on;
end

xlim([67.5 100]);
grid on;
yline([3048+180],"k--");
xline([70],"--k","LineWidth",1);
text(75,3550,"Apogee = 3228 m");
ylabel("Altitude (m)");
yticks(0:1000:4000);
title("Pressure Altitude of Each Atmosphere Model");
set(gca,"xdir","reverse");

nexttile;
airdatas = [];
for i = 1:num_files
    filename = files(i).name;
    dt = datetime(filename(1:18),"Format","d-MMM-yyyy-HH.m.s");
    load(filename);
    airdatas(:,i) = airdata.HGT;
end
my_std = std(airdatas,0,2);
plot(airdata.PRES/1000,my_std,"LineWidth",1);hold on;

xlim([67.5 100]);
grid on;
xline([70],"--k","LineWidth",1);
ylabel("Altitude (m)");
ylim([0 max(my_std)]);
set(gca,"xdir","reverse");
title("68% of PA's Are Closer Than This Amount To The Mean Model's PA");

nexttile;
my_range = range(airdatas,2);
plot(airdata.PRES/1000,my_range,"LineWidth",1);hold on;
xlim([67.5 100]);
grid on;
xline([70],"--k","LineWidth",1);
% xlabel("Pressure (kPa)");
ylabel("Altitude (m)");
ylim([0 max(my_range)]);
set(gca,"xdir","reverse");
title("Worst Altitude Range Between Models = " + string(round(max(my_range(1:14)),0)) + " m");

nexttile;
windmag = [];
for i = 1:num_files
    filename = files(i).name;
    dt = datetime(filename(1:18),"Format","d-MMM-yyyy-HH.m.s");
    load(filename);
    windmag(:,i) = vecnorm([airdata.UGRD airdata.VGRD],2,2);
end
windmagavg = mean(windmag,2);
windmagstd = std(windmag,0,2);
plot(airdata.PRES/1000,windmagavg,"LineWidth",1);hold on;
plot(airdata.PRES/1000,windmagavg+windmagstd,"--","LineWidth",1);
plot(airdata.PRES/1000,windmagavg-windmagstd,"--","LineWidth",1);
xlim([67.5 100]);
grid on;
xline([70],"--k","LineWidth",1);
xlabel("Pressure (kPa)");
ylabel("Velocity (m/s)");
ylim([0 20]);
set(gca,"xdir","reverse");
title("Wind Magnitude");

start_brake = interp1(mean(airdatas,2),airdata.PRES,alt_start);
nexttile(1);
fill([[start_brake start_brake]/1000 70 70],[0 4000 4000 0],"g","FaceAlpha",0.1,"EdgeColor","none");
text(mean([start_brake/1000 70+3]),2000,"Airbrakes","Color",[0 0.6 0]);
nexttile(2);
fill([[start_brake start_brake]/1000 70 70],[0 max(my_std) max(my_std) 0],"g","FaceAlpha",0.1,"EdgeColor","none");
text([100-0.1 start_brake/1000 70-0.1],[my_std(1) interp1(1:height(my_std),my_std,interp1(airdata.PRES,1:height(airdata),start_brake)) my_std(13)],string(round([my_std(1) interp1(1:height(my_std),my_std,interp1(airdata.PRES,1:height(airdata),start_brake)) my_std(13)],0)),"Color","r","FontWeight","bold","FontSize",12);
nexttile(3);
fill([[start_brake start_brake]/1000 70 70],[0 max(my_range) max(my_range) 0],"g","FaceAlpha",0.1,"EdgeColor","none");
text([100-0.1 start_brake/1000 70-0.1],[my_range(1) interp1(1:height(my_range),my_range,interp1(airdata.PRES,1:height(airdata),start_brake)) my_range(13)],string(round([my_range(1) interp1(1:height(my_range),my_range,interp1(airdata.PRES,1:height(airdata),start_brake)) my_range(13)],0)),"Color","r","FontWeight","bold","FontSize",12);
nexttile(4);
fill([[start_brake start_brake]/1000 70 70],[0 20 20 0],"g","FaceAlpha",0.1,"EdgeColor","none");

figure(51);
windavgu = mean(airdata.UGRD);
windavgv = mean(airdata.VGRD);

for i = 1:height(airdata)
    quiver(0,0,airdata.UGRD(i),airdata.VGRD(i));hold on;
end
quiver(0,0,windavgu,windavgv,"LineWidth",10);

%%

% clear;
% 
% sitename = "spaceport-midland";
% site = launchsites(sitename);
% 
% model = "nam";
% product = "conusnest.hiresf";
% 
% % q_month = 6;
% % q_day = 17;
% % qtime1 = datetime(2025, q_month, q_day, 12, 00, 00, TimeZone = "America/New_York");
% 
% q_years = [2024];
% q_days = 17:20;
% q_hours = [2 8 14];
% q_length = length(q_years)*length(q_days)*length(q_hours);
% 
% i = 1;
% for q_year = q_years
%     for q_day = q_days
%         qtime1 = datetime(q_year, 6, q_day, 2, 00, 00, TimeZone = "America/New_York");
%         qtime2 = datetime(q_year, 6, q_day, 14, 00, 00, TimeZone = "America/New_York");
%         qtimes = [qtime1 qtime2];
% 
%         ncep_object = ncep.analysis(model, product, qtimes);
% 
%         airdata_xarray = ncep_object.read_point(site.lat, site.lon, layer = digitsPattern + " mb", field = ["UGRD", "VGRD", "HGT", "TMP"]);
% 
%         airdata_xarray = sort_pressure_levels(airdata_xarray);
% 
%         for j = 1:size(airdata_xarray,1)
%             PRES = airdata_xarray(j,:,:).layer .* 100;
%             airdata = [PRES double(airdata_xarray(j,:,:))];
%             airdata = array2table(airdata, "VariableNames", {'PRES','HGT','TMP','UGRD','VGRD'});
% 
%             save(string(airdata_xarray(j,:,:).time, "d-MMM-yyyy-HH.m.s") + "-" + sitename + "-" + model + ".mat", "airdata");
% 
%             fprintf("Finished %d/%d\n",i,q_length);
%             i = i + 1;
%         end
%     end
% end
% 
% function data = sort_pressure_levels(data)
%     data.layer = str2double(extract(data.layer, digitsPattern));
%     data = sort(data, "layer", "descend");
% end