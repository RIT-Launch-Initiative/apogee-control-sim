%% print2size(fig, path, sz[, units])
% fig       figure handle
% path      destination file path and type
% sz        output [width, height]
% units     ({"pixels"} | valid values for figure.Units)

function print2size(fig, path, sz, units)
    arguments
        fig;
        path (1,1) string;
        sz (1,2) double;
        units (1,1) string = "pixels";
    end


    % using set() lets us set up and execute all the operations at once,
    % otherwise we would need annoying drawnow() calls between everything
    set(fig, WindowStyle = "normal", Units = units, Position = [fig.Position(1:2) sz]);
    drawnow; 

    exportgraphics(fig, path, ContentType = "vector");
end

