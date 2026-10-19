function dydt = ev2_rhs_v1(~,y,Cin,Dax,v,R,p,settings)
ni = settings.node_count-2;
y = y(:);
assert(numel(y)==ni && ni==69,'JWPE:M1:Dimension', ...
    'PF reduced state must contain 69 parent-SMX nodes.');
profile = [Cin;y;y(end)];
dz1 = PF_minmod_derivative(profile,settings.dz);
dz2 = PF_second_order_dispersion(profile,settings.dz);
A = 1;
rate = settings.XVSS_g_L.*A.*p.kb.*profile;
dydt = (-v.*dz1(2:end-1)+Dax.*dz2(2:end-1))/R- ...
    rate(2:end-1);
end
