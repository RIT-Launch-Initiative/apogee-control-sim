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
% data = retime(data, "Regular", "linear", SampleRate = 100);
import_cache.grim_data = data;

figure(name = "SRAD");
stackedplot(import_cache.grim_data);

rrc3_primary_path = pfullfile("data", "OMEN_RRC3_Primary.csv");
rrc3_secondary_path = pfullfile("data", "OMEN_RRC3_Secondary.csv");
import_cache.primary_data = import_rrc3(rrc3_primary_path);
import_cache.secondary_data = import_rrc3(rrc3_secondary_path);

figure(name = "Low rate")
stackedplot(import_cache.primary_data, import_cache.secondary_data);

function data = import_rrc3(file)
    arguments
        file (1,1) string {mustBeFile};
    end
    opts = delimitedTextImportOptions(NumVariables = 7, Delimiter = ",");
    opts.VariableNamesLine = 1;
    opts.VariableUnitsLine = 2;
    opts.DataLines = 3;
    opts.VariableTypes = ["double", "double", "double", "double", "double", "string", "double"];

    data = readtable(file, opts);%, VariableNamingRule = "preserve");
    data.Time = seconds(data.Time);
    event_locations = matches(data.Events, lettersPattern);
    event_table = eventtable(data.Time(event_locations), ...
        EventLabels = upper(data.Events(event_locations)));
    data.Events = [];
    
    data = table2timetable(data);
    data.Properties.Events = event_table;
end
