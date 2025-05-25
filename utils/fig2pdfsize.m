function fig2pdfsize(fig, name, sz)
    arguments
        fig;
        name (1,1) string;
        sz (1,2) double;
    end
    old_style = fig.WindowStyle;
    fig.WindowStyle = "normal";
    drawnow
    fig.Position(3:4) = sz;

    exportgraphics(fig, pfullfile("data", name), ContentType = "vector");

    % reset figure
    fig.WindowStyle = old_style;
end

