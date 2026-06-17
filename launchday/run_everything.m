tic
project_globals;
                                                                            
typical_variation
fprintf("Finished variation\n");
clear

generate_bounds;
fprintf("Finished generating bounds\n");
clear

% %% REMOVE
% generate_quant_luts

%%

jsonify_quant_lut;
fprintf("Exported lut\n");
clear

% controller_single
% controller_monte
toc