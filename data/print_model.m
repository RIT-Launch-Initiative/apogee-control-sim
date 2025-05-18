clear;
model_path = pfullfile("sim", "baro_processing");
[model_folder, model_name, ~] = fileparts(model_path);
output_file = fullfile(model_folder, model_name + ".pdf");

% import slreportgen.report.*
% import slreportgen.finder.*
% import mlreportgen.report.*
%
open_system(model_path);
hand = get_param(model_name, "Handle");
set_param(model_name, PaperPositionMode = "auto")
% set_param(0, ShowSimulationStatus = "off");
% saveas(hand, output_file, "pdf");
print("-dpdf", "-fillpage", "-s" + model_name, output_file);

cmd = "C:\Program Files\WindowsApps\25415Inkscape.Inkscape_1.3.2.0_x64__9waqn51p1ttv2\VFS\ProgramFilesX64\Inkscape\bin\inkscape.exe";
fmt = """%s"" ""%s"" --without_gui --actions=""" + ...
    "select-by-element:image;EditDelete;export-area-drawing;export-type=pdf;" + ...
    "export-filename='%s';export-do""";
full_command = sprintf(fmt, cmd, output_file, output_file);

system(full_command);
%
% rpt = Report(output_file);
% diag = Diagram(model_name);
% add(rpt, diag);
% close(rpt);
% rptview(rpt);
%
