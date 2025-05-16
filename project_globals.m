rkt_file = pfullfile("data", "OMEN.ork");
luts_file = pfullfile("data", "tables.mat");
data_file = pfullfile("data", "imports.mat");

doc = openrocket(rkt_file);
luts = matfile(luts_file, Writable = true);
imports = matfile(data_file, Writable = false);

apogee_target = 3300;

