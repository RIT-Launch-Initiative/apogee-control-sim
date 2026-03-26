% Export quant lut in specific human readable csv format for avionics passoff
% luts2csv(uppers, lowers, write_path)
% Inputs
%   uppers       (xarray)    Upper velocity bound xarray
%   lowers       (xarray)    Lower velocity bound xarray
%   write_path   (string)    Path to where csv files are written
% Outputs
%   one csv file
function luts2csv(uppers, lowers, write_path)
    arguments
        uppers xarray
        lowers xarray
        write_path string = ""
    end

    writematrix(["alt" "vel_low" "vel_high";uppers.("alt") double(lowers) double(uppers)], ...
    fullfile(write_path, "quant_lut.csv"));

    % writematrix(["alt" "vel";uppers.("alt") double(uppers)], ...
    %     fullfile(write_path, "upper_bounds.csv"));
    % 
    % writematrix(["alt" "vel";lowers.("alt") double(lowers)], ...
    %     fullfile(write_path, "lower_bounds.csv"));
end
