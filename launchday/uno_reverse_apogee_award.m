project_globals;

monte_apogee_guess = 3209; % [m]

pressure = double(interp1(airdata.HGT,airdata.PRES,monte_apogee_guess));

isa_guess = atmospalt(pressure);