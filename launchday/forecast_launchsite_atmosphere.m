clear;

% Gets airdata on the query date, for every hour, between two different
% hours of the day

q_month = 6;
q_day = 17;

query_cycle = hours(1);

qtime1 = datetime(2026, q_month, q_day, 5, 00, 00, TimeZone = "America/Chicago");
qtime2 = datetime(2026, q_month, q_day, 12, 00, 00, TimeZone = "America/Chicago");
qtimes = qtime1:query_cycle:qtime2;

i = 1;
for qtime = qtimes
    sitename = "spaceport-midland";
    site = launchsites(sitename);
    
    model = "gfs";
    product = "pgrb2.0p25";
    model_cycle = hours(6); % GFS updates every 6 hours
    
    % Find most recent model cycle that is before query time
    TT1 = timetable(datetime("now", TimeZone = "UTC") - hours(5),1); % It takes around 5 hours for a cycle to upload
    % TT1 = timetable(datetime("now", TimeZone = "UTC"),1);
    TT2 = retime(TT1,"regular", "mean", "TimeStep", model_cycle);
    rtime = TT2.Time;
    
    ncep_object = ncep.forecast(model, product, qtime, rtime);
    fprintf("ncep.forecast\n");
    airdata_xarray = ncep_object.read_point(site.lat, site.lon, layer = digitsPattern + " mb", field = ["UGRD", "VGRD", "HGT", "TMP"]);
    fprintf("ncep_object.read_point\n");
    airdata_xarray = sort_pressure_levels(airdata_xarray);
    fprintf("sort_pressure_levels\n");
    
    PRES = airdata_xarray.layer .* 100;
    airdata = [PRES double(airdata_xarray)];
    airdata = array2table(airdata, "VariableNames", {'PRES','HGT','TMP','UGRD','VGRD'});

    save(string(qtime, "d-MMM-yyyy-HH.m.s") + "-" + sitename + "-" + model + ".mat", "airdata");

    fprintf("Finished %d/%d\n",i,length(qtimes));
    i = i + 1;

    pause(15);
end

function data = sort_pressure_levels(data)
    data.layer = str2double(extract(data.layer, digitsPattern));
    data = sort(data, "layer", "descend");
end