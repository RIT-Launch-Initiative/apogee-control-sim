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

    % this specific combination of drawnow() and waitfor() is determined by
    % trial-and-error to fully repaint the figure before exportgraphics is
    % called

    drawnow;

    old_window = fig.WindowStyle;
    fig.WindowStyle = 'normal';
    waitfor(fig, WindowStyle = 'normal');

    fig.Units = units;
    fig.Position = [1 1 sz];
    waitfor(fig, Position = [1 1 sz]);

    exportgraphics(fig, path, ContentType = "vector");

    fig.WindowStyle = old_window;
    waitfor(fig, WindowStyle = old_window);
end

