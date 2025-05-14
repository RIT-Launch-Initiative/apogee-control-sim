clear;
data_path = pfullfile("data", "imports.mat");
import_cache = matfile(data_path, Writable = true);

grim_path = pfullfile("data", "grim_ascent_fast.csv");
data = readtable(grim_path, VariableNamingRule = "preserve");
data.Properties.VariableNames = ["Time", "accel_x", "accel_y", "accel_z", "gyro_x", "gyro_y", "gyro_z", "baro"];
data.Properties.VariableUnits = ["ms", "m/s^2", "m/s^2", "m/s^2", "rad/s", "rad/s", "rad/s", "kPa"];
data.Time = milliseconds(data.Time);
data = table2timetable(data);
% data = data(timerange(seconds(-Inf), seconds(200)), :);
data = retime(data, "Regular", "linear", SampleRate = 100);
import_cache.grim_data = data;


