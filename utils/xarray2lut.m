% Convert xarray to Simulink lookup table object for Lookup Table blocks
% lut = xarray2lut(xarr, axes)
% Inputs
%   xarr    (xarray)    Array to convert
%   axes    (string)    Input order - same names as axes in xarray, which must be numeric
% Outputs
%   lut     (Simulink.LookupTable)
function lut = xarray2lut(xarr, axes, unname)
    arguments
        xarr xarray 
        axes (1,:) string;
        unname (1,1) string = ""
    end
    lut = Simulink.LookupTable;

    xarr = squeeze(xarr); % get rid of 1D dimensions
    xarr = xarr.align(axes); % bring lookup dimensions forward in the order requried
    xarr = sort(xarr, axes, "ascend"); % sort for lookup

    % assign axes and data
    for i_ax = 1:length(axes);
        axis = axes(i_ax);
        coord = xarr.(axis);
        if ~isnumeric(coord)
            error("Axis '%s' is not numeric", axis);
        end

        lut.Breakpoints(i_ax).FieldName = axis;
        lut.Breakpoints(i_ax).Value = coord;
    end
    lut.Table.Value = double(xarr);

    % needs unique name for code generation
    if unname == ""
        unname = sprintf("%lx", keyHash(xarr));
    end
    lut.StructTypeInfo.Name = sprintf("LUT_%s_%s", join(axes, "_"), unname);
end
