% sitename = "urrg";
% model = "gfs";
% product = "pgrb2.0p25";
% 
% site = launchsites(sitename);
% launchtime = datetime(2026, 03, 27, 14, 00, 00, TimeZone = "America/New_York");
% time_nice = string(launchtime.Day)+"-"+string(launchtime.Month)+"-"+string(launchtime.Year)+"-";
% time_nice = time_nice+string(launchtime.Hour)+"."+string(launchtime.Minute)+"-";
% time_nice = time_nice+string(launchtime.Second);
% airdata = atmosphere(model, product, site.lat, site.lon, launchtime, minpres = 450);
% 
% save(time_nice+"-"+sitename+"-"+model+".mat","airdata")
% save("launchsite.mat","site","sitename");


sitename = "urrg";
site = launchsites(sitename);

validtime = datetime(2026, 04, 11, 12, 00, 00, TimeZone = "America/New_York");

reftime = datetime(2026, 04, 10, 11, 00, 00, TimeZone = -hours(6)) + hours(12);

% nam_ref = ncep.forecast("gfs", "pgrb2.0p25", validtime, reftime);

gfs_ref = ncep.forecast("gfs", "pgrb2.0p25", validtime, reftime);
gfs_wind = gfs_ref.read_point(site.lat, site.lon, ...
    layer = digitsPattern + " mb", field = ["UGRD", "VGRD", "HGT", "TMP"]);
gfs_wind = sort_pressure_levels(gfs_wind);

% gfs_wind = gfs_wind.index(time = 1).range(layer = [400 1000]).align("layer");

function data = sort_pressure_levels(data)
    data.layer = str2double(extract(data.layer, digitsPattern));
    data = sort(data, "layer", "descend");
end


disp("");


sitename = "urrg";
model = "gfs";
product = "pgrb2.0p25";

site = launchsites(sitename);
launchtime = datetime(2026, 04, 10, 12, 00, 00, TimeZone = "America/New_York"); % Year month day
time_nice = string(launchtime.Day)+"-"+string(launchtime.Month)+"-"+string(launchtime.Year)+"-";
time_nice = time_nice+string(launchtime.Hour)+"."+string(launchtime.Minute)+"-";
time_nice = time_nice+string(launchtime.Second);
airdata = atmosphere(model, product, site.lat, site.lon, launchtime, minpres = 450);

save(time_nice+"-"+sitename+"-"+model+".mat","airdata")







% sitename = "urrg";
% model = "gfs";
% product = "pgrb2.1p00";
% 
% site = launchsites(sitename);
% launchtime = datetime(2026, 03, 28, 4, 00, 00, TimeZone = "America/New_York");
% time_nice = string(launchtime.Day)+"-"+string(launchtime.Month)+"-"+string(launchtime.Year)+"-";
% time_nice = time_nice+string(launchtime.Hour)+"."+string(launchtime.Minute)+"-";
% time_nice = time_nice+string(launchtime.Second);
% airdata = atmosphere(model, product, site.lat, site.lon, launchtime, minpres = 450);
% 
% save(time_nice+"-"+sitename+"-"+model+".mat","airdata")



% 
% sitename = "spaceport-midland";
% model = "gfs";
% product = "pgrb2.0p25";
% 
% site = launchsites(sitename);
% launchtime = datetime(2026, 03, 27, 14, 00, 00, TimeZone = "America/New_York");
% time_nice = string(launchtime.Day)+"-"+string(launchtime.Month)+"-"+string(launchtime.Year)+"-";
% time_nice = time_nice+string(launchtime.Hour)+"."+string(launchtime.Minute)+"-";
% time_nice = time_nice+string(launchtime.Second);
% airdata = atmosphere(model, product, site.lat, site.lon, launchtime, minpres = 450);
% 
% save(time_nice+"-"+sitename+"-"+model+".mat","airdata")
% save("launchsite.mat","site","sitename");