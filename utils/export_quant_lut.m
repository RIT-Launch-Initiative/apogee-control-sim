% Convert xarray to human readable csv to pass off to avionics
% export_quant_lut(xarr)
% Inputs
%   xarr    (xarray)    Array to convert
% Outputs
%   csv file in data folder
function export_quant_lut(lut, filename)
    arguments
        lut xarray;
        filename string = "exported_quant_lut.csv"
    end

    writematrix(double(lut), filename);
end
