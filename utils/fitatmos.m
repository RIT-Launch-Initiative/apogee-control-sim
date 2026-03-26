function airdata_pres_alt_coeffs = fitatmos(airdata)
    arguments
        airdata table
    end

    poly_order = 5;
    airdata_pres_alt_coeffs = polyfit(airdata.PRES,airdata.HGT,poly_order);

end
