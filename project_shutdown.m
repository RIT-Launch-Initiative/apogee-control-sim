set(groot, "DefaultFigureWindowStyle", "remove");
set(groot, "DefaultAxesFontSize", "remove"); 
set(groot, "DefaultAxesNextPlot", "remove"); % default hold-on

% set all grids default on
grids = compose("defaultAxes%sGrid", ["X", "Y", "Z"]);
for grid = grids
    set(groot, grid, "remove");
end

clear grids;
