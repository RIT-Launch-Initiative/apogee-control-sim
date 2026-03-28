sitename = "urrg";
model = "gfs";

site = launchsites(sitename);
launchtime = datetime(2026, 03, 25, 11, 00, 00, TimeZone = -hours(6));
time_nice = string(launchtime.Day)+"-"+string(launchtime.Month)+"-"+string(launchtime.Year)+"-";
time_nice = time_nice+string(launchtime.Hour)+"."+string(launchtime.Minute)+"-";
time_nice = time_nice+string(launchtime.Second);
airdata = atmosphere("gfs", "pgrb2.1p00", site.lat, site.lon, launchtime, minpres = 450);

save(time_nice+"-"+sitename+"-"+model+".mat","airdata")
save("launchsite.mat","site","sitename");

% plot(airdata.HGT,airdata.PRES);grid on;