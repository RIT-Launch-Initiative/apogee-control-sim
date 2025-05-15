function export_at_size(fig, name, sz)
    old_style = fig.WindowStyle;
    fig.WindowStyle = "normal";
    drawnow
    fig.Position(3:4) = sz;

    exportgraphics(fig, pfullfile("data", name));

    % reset figure
    fig.WindowStyle = old_style;
end

