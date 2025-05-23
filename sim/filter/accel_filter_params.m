function params = alt_filter_params(mode)
    arguments 
        mode (1,1) string
    end

    params.input_rate = 100;
    params.output_rate = 10;

    switch mode
        case "none"
            params.num = 1;
            params.den = 1;
            params.avg = 1;

        case "designed"
            params.num = 1;
            params.den = 1;
            params.avg = 1;

        otherwise 
            error("Unrecognized acceleration filter mode %s", mode);
    end
end
