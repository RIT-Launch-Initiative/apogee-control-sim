tic
project_globals;
                                                                            
typical_variation
fprintf("Finished variation\n");
clear

generate_bounds;
fprintf("Finished generating bounds\n");
clear

jsonify_quant_lut;
fprintf("Exported lut");
clear

% controller_single
controller_monte
toc