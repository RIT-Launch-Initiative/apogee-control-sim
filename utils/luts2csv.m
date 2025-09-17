% Export quant lut in specific human readable csv format for avionics passoff
% luts2csv(quant_ctrl, uppers, lowers, write_path)
% Inputs
%   quant_ctrl   (xarray)    Quantile lut xarray
%   uppers       (xarray)    Upper velocity bound xarray
%   lowers       (xarray)    Lower velocity bound xarray
%   write_path   (string)    Path to where csv files are written
% Outputs
%   three csv files
function luts2csv(quant_ctrl, uppers, lowers, write_path)
    arguments
        quant_ctrl xarray
        uppers xarray
        lowers xarray
        write_path string = ""
    end

    writematrix(["alt" "vel";uppers.("alt") double(uppers)], ...
        fullfile(write_path, "upper_bounds.csv"));

    writematrix(["alt" "vel";lowers.("alt") double(lowers)], ...
        fullfile(write_path, "lower_bounds.csv"));

    writematrix(["vel_v alt_>" quant_ctrl.("alt")'; ...
        quant_ctrl.("quant") double(quant_ctrl)], ...
        fullfile(write_path, "quant.csv"));
end
