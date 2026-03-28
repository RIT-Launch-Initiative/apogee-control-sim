tic
typical_variation
fprintf("Finished variation\n");
clear

generate_bounds;
fprintf("Finished generating bounds\n");
clear

% generate_luts
% generate_quant_luts
% fprintf("Finished generating lut\n");
% clear

jsonify_quant_lut;
fprintf("Exported lut");
clear

% controller_single
controller_monte
toc