ground_height_real = launchsites("spaceport-midland").alt;
ground_press = interp1(airdata.HGT, airdata.PRES, ground_height_real);
ground_height_isa = atmospalt(double(ground_press));

apogee_height_isa = 3048 + ground_height_isa;
[~,~,apogee_press,~,~,~] = atmosisa(apogee_height_isa);
apogee_height_real = interp1(airdata.PRES, airdata.HGT, apogee_press);
apogee_height_real_AGL = apogee_height_real - ground_height_real;

apogee_target = double(apogee_height_real_AGL);

clear ground_height_real ground_press ground_height_isa apogee_height_isa apogee_press apogee_height_real apogee_height_real_AGL;

% Eventually make this create .mat file