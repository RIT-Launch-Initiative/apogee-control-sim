close all;

project_globals;

% x=linspace(5e4,10e4,1000);
%
% % ref
% y_ref=interp1(airdata.PRES,airdata.HGT,x);
% 
% % fmin
% wrapper_func = @(vars) true_func(vars, airdata);
% [vars]=fminsearch(wrapper_func,[101325 0.190284 145366.45 0.3048]);
% a=vars(1);b=vars(2);c=vars(3);d=vars(4);
% y_fmin=(1 - (x ./ a).^(b)) .* c * d;

% polytfit (this resulted in best fit with 5th order)
poly_order = 5;
airdata_pres_alt_coeffs = polyfit(airdata.PRES,airdata.HGT,poly_order);
% y_poly=polyval(airdata_pres_alt_coeffs,x);

% % compare
% diff_fmin=abs(y_ref-y_fmin);
% diff_poly=abs(y_ref-y_poly);
% diff_isa=abs(y_ref-((1 - (x ./ 101325).^(0.190284)) .* 145366.45 * 0.3048));
% 
% rmse_fmin=rmse(y_ref,y_fmin);
% rmse_poly=rmse(y_ref,y_poly);
% 
% figure();
% plot(x,diff_fmin,"LineWidth",2,"DisplayName","fmin");hold on;
% plot(x,diff_poly,"LineWidth",2,"DisplayName","poly");
% plot(x,diff_isa,"LineWidth",2,"DisplayName","isa");
% legend;
% 
% fprintf("rmse fmin: %f\n",rmse_fmin);
% fprintf("rmse poly: %f\n",rmse_poly);
%
% clear x y_ref wrapper_func vars a b c d y_fmin poly_order y_poly
%
% function cost = true_func(vars, airdata)
%     a=vars(1);b=vars(2);c=vars(3);d=vars(4);
%     pressure = airdata.PRES;
%     alt = (1 - (pressure ./ a).^(b)) .* c * d;
%     cost = rmse(airdata.HGT,alt);
% end