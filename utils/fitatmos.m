function airdata_pres_alt_coeffs = fitatmos(airdata)
    arguments
        airdata table
    end

    poly_order = 5;
    airdata_pres_alt_coeffs = polyfit(airdata.PRES(1:7),airdata.HGT(1:7),poly_order);

end