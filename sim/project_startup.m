set(groot, "DefaultFigureWindowStyle", "docked");
set(groot, "DefaultAxesFontSize", 14); 
set(groot, "DefaultAxesNextPlot", "add"); % default hold-on

% set all grids default on
grids = compose("defaultAxes%sGrid", ["X", "Y", "Z"]);
for grid = grids
    set(groot, grid, "on");
end

clear grids;
