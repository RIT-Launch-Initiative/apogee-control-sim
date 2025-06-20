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
    fig.WindowStyle = 'normal';
    fig.Units = units;
    waitfor(fig, WindowStyle = 'normal');
    fig.Position = [1 1 sz];
    waitfor(fig, Position = [1 1 sz]);
    exportgraphics(fig, path, ContentType = "vector");
end

