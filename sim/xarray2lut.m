% Convert xarray to Simulink lookup table
function lut = xarray2lut(xarr)
    lut = Simulink.LookupTable;
    xarr = squeeze(xarr);
    xarr = sort(xarr, xarr.axes, "ascend");
    for i_ax = 1:naxes(xarr)
        if ~isnumeric(xarr.coordinates{i_ax})
            error("All coordinates must be numeric");
        end

        lut.Breakpoints(i_ax).Value = xarr.coordinates{i_ax};
    end
    lut.Table.Value = double(xarr);
    lut.StructTypeInfo.Name = "LUT";
end
